`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ  = 100000000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx,
    output reg        tx_busy
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0]  state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0]  bit_idx = 0;
    reg [7:0]  tx_buf = 8'h00;

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            clk_count <= 0;
            bit_idx   <= 0;
            tx_buf    <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    tx      <= 1'b1; // Fixed: was "1 meb1"
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        tx_buf    <= tx_data;
                        tx_busy   <= 1'b1;
                        clk_count <= 0;
                        state     <= START;
                    end
                end

                START: begin
                    tx <= 1'b0; // Send Start bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        bit_idx   <= 0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    tx <= tx_buf[bit_idx];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1'b1;
                        end else begin
                            bit_idx <= 0;
                            state   <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1; // Send Stop bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        tx_busy   <= 1'b0;
                        state     <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule