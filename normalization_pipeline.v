module min_max_normalizer (
    input clk,
    input [11:0] log_pixel_in,
    input [11:0] frame_min,
    input [11:0] frame_max,
    output reg [7:0] enhanced_pixel_out
);
    
    // Memory for the Reciprocal Look-Up Table (4096 entries of 16-bits)
    reg [15:0] reciprocal_rom [0:4095];
    
    initial begin
        $readmemh("reciprocal.mem", reciprocal_rom);
    end

    // Pipeline registers for the math stages
    reg [11:0] delta;
    reg [11:0] numerator;
    reg [15:0] scale_factor;
    reg [27:0] scaled_result;

    always @(posedge clk) begin
        // Stage 1: Calculate Delta and Numerator (val - min)
        delta <= (frame_max > frame_min) ? (frame_max - frame_min) : 12'd1;
        numerator <= (log_pixel_in > frame_min) ? (log_pixel_in - frame_min) : 12'd0;

        // Stage 2: Fetch the inverse multiplier from the Block RAM
        scale_factor <= reciprocal_rom[delta];

        // Stage 3: Multiply
        scaled_result <= numerator * scale_factor;

        // Stage 4: Shift right by 16 bits (divide by 65536) and clamp to 8-bit max
        if ((scaled_result >> 16) > 28'd255)
            enhanced_pixel_out <= 8'd255;
        else
            enhanced_pixel_out <= scaled_result[23:16]; 
    end
endmodule