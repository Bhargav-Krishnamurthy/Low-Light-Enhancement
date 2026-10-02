`timescale 1ns / 1ps

module min_max_normalizer (
    input clk,
    input [11:0] log_pixel_in,
    input [11:0] frame_min,
    input [11:0] frame_max,
    output reg [7:0] enhanced_pixel_out
);
    
    // Force LUT array into hardware Block RAM (BRAM)
    (* ram_style = "block" *) reg [15:0] reciprocal_rom [0:4095];
    
    initial begin
        $readmemh("reciprocal.mem", reciprocal_rom);
    end

    // Stage 1: Delta & Numerator
    reg [11:0] delta;
    reg [11:0] numerator_s1;

    always @(posedge clk) begin
        delta        <= (frame_max > frame_min) ? (frame_max - frame_min) : 12'd1;
        numerator_s1 <= (log_pixel_in > frame_min) ? (log_pixel_in - frame_min) : 12'd0;
    end

    // Stage 2: Synchronous BRAM Read & Delay Alignment
    reg [15:0] scale_factor;
    reg [11:0] numerator_s2;

    always @(posedge clk) begin
        scale_factor <= reciprocal_rom[delta];
        numerator_s2 <= numerator_s1; // Synchronizes 1-clock BRAM delay
    end

    // Stage 3: DSP48 Multiplication
    reg [27:0] scaled_result;

    always @(posedge clk) begin
        scaled_result <= numerator_s2 * scale_factor;
    end

    // Stage 4: Output Clamp
    always @(posedge clk) begin
        if ((scaled_result >> 16) > 28'd255)
            enhanced_pixel_out <= 8'd255;
        else
            enhanced_pixel_out <= scaled_result[23:16]; 
    end

endmodule