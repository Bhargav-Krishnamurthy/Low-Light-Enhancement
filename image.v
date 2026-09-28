module gaussian_5x5 (
    input clk,
    input [7:0] p11, p12, p13, p14, p15, // Row 1 (from line buffer 4)
    input [7:0] p21, p22, p23, p24, p25, // Row 2 (from line buffer 3)
    input [7:0] p31, p32, p33, p34, p35, // Row 3
    input [7:0] p41, p42, p43, p44, p45, // Row 4
    input [7:0] p51, p52, p53, p54, p55, // Row 5
    output reg [7:0] pixel_out
);

    reg [16:0] sum; 

    always @(posedge clk) begin
        // Perform the Multiply and Accumulate (MAC) using the kernel weights
        sum <= (p11*1) + (p12*4) + (p13*7) + (p14*4) + (p15*1) +
               (p21*4) + (p22*16) + (p23*26) + (p24*16) + (p25*4) +
	       (p31*7) + (p32*26) + (p33*41) + (p34*26) + (p35*7) +
	       (p41*4) + (p42*16) + (p43*26) + (p44*16) + (p45*4) +
	       (p51*1) + (p52*4) + (p53*7) + (p54*4) + (p55*1);
                              
        // Divide by 273 using a hardware trick: multiply by 15, divide by 4096 (shift right 12)
        pixel_out <= (sum * 32'd15) >> 12;
    end
endmodule
