`timescale 1ns / 1ps

module gaussian_5x5 (
    input clk,
    input [7:0] p11, p12, p13, p14, p15, 
    input [7:0] p21, p22, p23, p24, p25, 
    input [7:0] p31, p32, p33, p34, p35, 
    input [7:0] p41, p42, p43, p44, p45, 
    input [7:0] p51, p52, p53, p54, p55, 
    output reg [7:0] pixel_out
);

    // Stage 1: Partial Row Sums (Pipelined)
    reg [13:0] row1_sum, row2_sum, row3_sum, row4_sum, row5_sum;

    always @(posedge clk) begin
        row1_sum <= (p11*1) + (p12*4)  + (p13*7)  + (p14*4)  + (p15*1);
        row2_sum <= (p21*4) + (p22*16) + (p23*26) + (p24*16) + (p25*4);
        row3_sum <= (p31*7) + (p32*26) + (p33*41) + (p34*26) + (p35*7);
        row4_sum <= (p41*4) + (p42*16) + (p43*26) + (p44*16) + (p45*4);
        row5_sum <= (p51*1) + (p52*4)  + (p53*7)  + (p54*4)  + (p55*1);
    end

    // Stage 2: Combined Total Sum
    reg [16:0] total_sum;

    always @(posedge clk) begin
        total_sum <= row1_sum + row2_sum + row3_sum + row4_sum + row5_sum;
    end

    // Stage 3: Multiply and Shift
    reg [31:0] scaled_sum;

    always @(posedge clk) begin
        scaled_sum <= total_sum * 32'd15;
        pixel_out  <= scaled_sum >> 12;
    end

endmodule