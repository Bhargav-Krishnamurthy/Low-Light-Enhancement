`timescale 1ns / 1ps
module log_transform_lut (
    input clk,
    input [7:0] pixel_in,
    output reg [11:0] log_pixel_out
);
    reg [11:0] log_rom [0:255]; 
    initial $readmemh("log_values.mem", log_rom); 
    always @(posedge clk) log_pixel_out <= log_rom[pixel_in]; 
endmodule