`timescale 1ns / 1ps
module image_enhancement_top #(
    parameter IMG_WIDTH = 256 
)(
    input clk,
    input rst,
    input valid_in,
    input frame_start,
    input [7:0] pixel_in,
    output [7:0] pixel_out,
    output valid_out
);
    parameter SHIFT_LENGTH = (4 * IMG_WIDTH) + 5;
    reg [7:0] shift_reg [0:SHIFT_LENGTH-1];
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < SHIFT_LENGTH; i = i + 1) shift_reg[i] <= 8'd0;
        end else if (valid_in) begin
            for (i = SHIFT_LENGTH - 1; i > 0; i = i - 1) shift_reg[i] <= shift_reg[i-1];
            shift_reg[0] <= pixel_in;
        end
    end

    wire [7:0] gaussian_out;
    wire [11:0] log_out, current_min, current_max;

    gaussian_5x5 u_gaussian (.clk(clk), .p11(shift_reg[(4*IMG_WIDTH)+4]), .p12(shift_reg[(4*IMG_WIDTH)+3]), .p13(shift_reg[(4*IMG_WIDTH)+2]), .p14(shift_reg[(4*IMG_WIDTH)+1]), .p15(shift_reg[(4*IMG_WIDTH)+0]), .p21(shift_reg[(3*IMG_WIDTH)+4]), .p22(shift_reg[(3*IMG_WIDTH)+3]), .p23(shift_reg[(3*IMG_WIDTH)+2]), .p24(shift_reg[(3*IMG_WIDTH)+1]), .p25(shift_reg[(3*IMG_WIDTH)+0]), .p31(shift_reg[(2*IMG_WIDTH)+4]), .p32(shift_reg[(2*IMG_WIDTH)+3]), .p33(shift_reg[(2*IMG_WIDTH)+2]), .p34(shift_reg[(2*IMG_WIDTH)+1]), .p35(shift_reg[(2*IMG_WIDTH)+0]), .p41(shift_reg[(1*IMG_WIDTH)+4]), .p42(shift_reg[(1*IMG_WIDTH)+3]), .p43(shift_reg[(1*IMG_WIDTH)+2]), .p44(shift_reg[(1*IMG_WIDTH)+1]), .p45(shift_reg[(1*IMG_WIDTH)+0]), .p51(shift_reg[4]), .p52(shift_reg[3]), .p53(shift_reg[2]), .p54(shift_reg[1]), .p55(shift_reg[0]), .pixel_out(gaussian_out));
    log_transform_lut  u_log (.clk(clk), .pixel_in(gaussian_out), .log_pixel_out(log_out));

    // Valid Shift Register: Delays the trigger by exactly 8 clock cycles
    reg [7:0] valid_pipe = 0;
    always @(posedge clk) begin
        if (rst) valid_pipe <= 0;
        else valid_pipe <= {valid_pipe[6:0], valid_in};
    end
    assign valid_out = valid_pipe[7];

    // Tracker taps cycle 4 (valid_pipe[3]) exactly when Log LUT is done
    min_max_tracker u_tracker (
        .clk(clk), .frame_start(frame_start), 
        .valid_pixel(valid_pipe[3]), 
        .pixel_in(log_out), .frame_min(current_min), .frame_max(current_max)
    );

    min_max_normalizer u_normalizer(.clk(clk), .log_pixel_in(log_out), .frame_min(current_min), .frame_max(current_max), .enhanced_pixel_out(pixel_out));
endmodule