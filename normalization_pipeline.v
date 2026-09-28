module normalization_pipeline (
    input clk,
    input [11:0] pixel_in,
    input [11:0] frame_min,
    input [11:0] frame_max,
    output reg [7:0] pixel_out
);

    // Pipeline registers for each clock cycle stage
    reg [11:0] num_diff;
    reg [11:0] den_diff;
    reg [23:0] scale_factor;
    reg [35:0] mult_result;

    // The Reciprocal LUT: 4096 entries, 24-bits wide
    // Stores the pre-calculated value of: (255 * 4096) / index
    reg [23:0] reciprocal_lut [0:4095]; 

    initial begin
        // Load the pre-calculated multiplier value
        $readmemh("reciprocal.mem", reciprocal_lut); 
    end

    always @(posedge clk) begin

        // STAGE 1: Subtraction
        // Calculate the numerator (V_in - V_min)
        num_diff <= (pixel_in > frame_min) ? (pixel_in - frame_min) : 12'd0;
	// Calculate the denominator value and prevent division by 0 error
        den_diff <= (frame_max > frame_min) ? (frame_max - frame_min) : 12'd1;

        // STAGE 2: Memory Read(reading from the LUT)
        scale_factor <= reciprocal_lut[den_diff]; 

        // STAGE 3: Multiply
        // Multiply the pixel difference by the scaled fraction
        mult_result <= num_diff * scale_factor;
        
        // STAGE 4: Shift and Output
        // Undo the 4096 scaling by shifting right 12 bits (>> 12).
        // The result is our final 8-bit pixel (clamped to 255 just in case).
        if (mult_result[35:12] > 255) 
            pixel_out <= 8'd255;
        else 
            pixel_out <= mult_result[19:12]; 
    end
endmodule
