`timescale 1ns / 1ps
module min_max_normalizer (
    input clk,
    input [11:0] log_pixel_in,
    input [11:0] frame_min,
    input [11:0] frame_max,
    output reg [7:0] enhanced_pixel_out
);
    (* ram_style = "block" *) reg [15:0] reciprocal_rom [0:4095];
    initial $readmemh("reciprocal.mem", reciprocal_rom);

    reg [11:0] delta, numerator_s1, numerator_s2;
    reg [15:0] scale_factor;
    reg [27:0] scaled_result;

    always @(posedge clk) begin
        delta        <= (frame_max > frame_min) ? (frame_max - frame_min) : 12'd1;
        numerator_s1 <= (log_pixel_in > frame_min) ? (log_pixel_in - frame_min) : 12'd0;
        
        scale_factor <= reciprocal_rom[delta];
        numerator_s2 <= numerator_s1; 
        
        scaled_result <= numerator_s2 * scale_factor;
        
        if ((scaled_result >> 16) > 28'd255)
            enhanced_pixel_out <= 8'd255;
        else
            enhanced_pixel_out <= scaled_result[23:16]; 
    end
endmodule