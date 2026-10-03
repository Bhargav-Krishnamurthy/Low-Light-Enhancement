`timescale 1ns / 1ps
module rgb_enhancement_top #(
    parameter IMG_WIDTH = 256
)(
    input clk,
    input rst,
    input valid_in,
    input frame_start,
    input [23:0] pixel_in,   
    output [23:0] pixel_out,
    output valid_out
);
    wire [7:0] r_out, g_out, b_out;
    wire r_valid; // Since lines are identical in length, we only need to monitor one.

    image_enhancement_top #(.IMG_WIDTH(IMG_WIDTH)) u_red (.clk(clk), .rst(rst), .valid_in(valid_in), .frame_start(frame_start), .pixel_in(pixel_in[23:16]), .pixel_out(r_out), .valid_out(r_valid));
    image_enhancement_top #(.IMG_WIDTH(IMG_WIDTH)) u_green (.clk(clk), .rst(rst), .valid_in(valid_in), .frame_start(frame_start), .pixel_in(pixel_in[15:8]), .pixel_out(g_out), .valid_out());
    image_enhancement_top #(.IMG_WIDTH(IMG_WIDTH)) u_blue (.clk(clk), .rst(rst), .valid_in(valid_in), .frame_start(frame_start), .pixel_in(pixel_in[7:0]), .pixel_out(b_out), .valid_out());

    assign pixel_out = {r_out, g_out, b_out};
    assign valid_out = r_valid; 
endmodule