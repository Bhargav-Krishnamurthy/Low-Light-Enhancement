`timescale 1ns / 1ps
module log_transform_lut (
    input clk,
    input en,
    input [7:0] pixel_in,
    output reg [11:0] log_pixel_out
);
    reg [11:0] log_rom [0:255]; 
    initial begin
        $readmemh("log_values.mem", log_rom); 
    end
    always @(posedge clk) begin
        if (en) log_pixel_out <= log_rom[pixel_in]; 
    end
endmodule