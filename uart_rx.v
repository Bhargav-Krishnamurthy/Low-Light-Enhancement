`timescale 1ns / 1ps

module uart_rx #(
    parameter CLK_FREQ  = 100000000, // 100 MHz clock
    parameter BAUD_RATE = 115200     // 115,200 baud
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_done
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE; // 868 cycles
    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0]  state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0]  bit_idx = 0;
    reg        rx_sync1 = 1'b1, rx_sync2 = 1'b1;

    // Double-flop synchronizer
    always @(posedge clk) begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_idx   <= 0;
            rx_data   <= 8'h00;
            rx_done   <= 1'b0;
        end else begin
            rx_done <= 1'b0;

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_idx   <= 0;
                    if (rx_sync2 == 1'b0) // Falling edge
                        state <= START;
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_sync2 == 1'b0) begin
                            clk_count <= 0;
                            state     <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count        <= 0;
                        rx_data[bit_idx] <= rx_sync2;
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1'b1;
                        end else begin
                            bit_idx <= 0;
                            state   <= STOP;
                        end
                    end
                end

                STOP: begin
                    // Wait 1.5 bit periods (1302 cycles) to clear STOP bit safely
                    if (clk_count < (CLKS_PER_BIT * 3) / 2 - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        rx_done   <= 1'b1;
                        clk_count <= 0;
                        state     <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule