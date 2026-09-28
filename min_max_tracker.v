module min_max_tracker (
    input clk,
    input frame_start,      // Signal indicating a new image has started
    input valid_pixel,      // High when a pixel is on the belt
    input [11:0] pixel_in,
    output reg [11:0] frame_min,
    output reg [11:0] frame_max
);
    
    reg [11:0] current_min;
    reg [11:0] current_max;

    always @(posedge clk) begin
        if (frame_start) begin
            // When a new frame starts, save the old min/max for the Normalizer to use
            frame_min <= current_min;
            frame_max <= current_max;
            
            // Reset trackers for the new frame
            current_min <= 12'hFFF; // Max possible 12-bit value
            current_max <= 12'h000; // min possible 12-bit value
        end else if (valid_pixel) begin
            if (pixel_in < current_min) current_min <= pixel_in;
            if (pixel_in > current_max) current_max <= pixel_in;
        end
    end
endmodule
