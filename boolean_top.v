`timescale 1ns / 1ps

module boolean_top (
    input  wire        clk,          // Pin F14 (100 MHz)[cite: 4]
    input  wire        rst,          // Pin J2 (BTN0)[cite: 4]
    input  wire        rx,           // Pin U11[cite: 4]
    output wire        tx,           // Pin V12[cite: 4]
    output wire [15:0] led           // Diagnostic LEDs[cite: 4]
);

    // Synchronous Reset
    reg rst_sync1 = 1'b1, rst_sync2 = 1'b1;
    always @(posedge clk) begin
        rst_sync1 <= rst;
        rst_sync2 <= rst_sync1;
    end

    // Heartbeat Counter
    reg [26:0] heartbeat = 0;
    always @(posedge clk) begin
        heartbeat <= heartbeat + 1'b1;
    end

    // UART Receiver
    wire [7:0] rx_byte;
    wire       rx_done;

    uart_rx #(
        .CLK_FREQ(100000000),
        .BAUD_RATE(115200)
    ) u_rx (
        .clk(clk),
        .rst(rst_sync2),
        .rx(rx),
        .rx_data(rx_byte),
        .rx_done(rx_done)
    );

    // Loopback Logic
    reg [7:0] loopback_data = 8'h00;
    reg       loopback_start = 1'b0;
    wire      tx_busy;

    always @(posedge clk) begin
        if (rst_sync2) begin
            loopback_data  <= 8'h00;
            loopback_start <= 1'b0;
        end else begin
            loopback_start <= 1'b0;
            if (rx_done && !tx_busy) begin
                loopback_data  <= rx_byte;
                loopback_start <= 1'b1;
            end
        end
    end

    // UART Transmitter
    uart_tx #(
        .CLK_FREQ(100000000),
        .BAUD_RATE(115200)
    ) u_tx (
        .clk(clk),
        .rst(rst_sync2),
        .tx_start(loopback_start),
        .tx_data(loopback_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Diagnostic LEDs
    assign led[15]   = heartbeat[26];      // Blinks at ~0.7 Hz
    assign led[14]   = rst_sync2;          // Active High Reset
    assign led[13:9] = 5'b0;
    assign led[8]    = tx_busy;            // High during transmission
    assign led[7:0]  = loopback_data;      // Echoed data byte
endmodule