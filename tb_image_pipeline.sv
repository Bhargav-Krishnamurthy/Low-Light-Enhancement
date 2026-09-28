`timescale 1ns / 1ps

module tb_image_pipeline;


    parameter IMG_WIDTH  = 256;
    parameter IMG_HEIGHT = 256;
    parameter TOTAL_PIXELS = IMG_WIDTH * IMG_HEIGHT;
    
    // 5x5 window needs roughly 2 full rows + some registers before first valid output
    parameter PIPELINE_DELAY = (2 * IMG_WIDTH) + 10; 

    // Signals
    logic clk;
    logic rst;
    logic frame_start;
    logic [23:0] pixel_in;
    logic [23:0] pixel_out;
    logic [23:0] in_image_mem [0:TOTAL_PIXELS-1];

    integer out_file;

    // Instantiate your Top-Level Factory
    rgb_enhancement_top #(
        .IMG_WIDTH(IMG_WIDTH) // Explicitly map the 256 width
    ) u_dut (
        .clk(clk),
        .rst(rst),
        .frame_start(frame_start),
        .pixel_in(pixel_in),
        .pixel_out(pixel_out)
    );

    // Generate the 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        frame_start = 0;
        pixel_in = 0;
        
        // Load the image
        $readmemh("image_hex.txt", in_image_mem);
        
        // Open the collection bin
        out_file = $fopen("output_hex.txt", "w");
        if (out_file == 0) begin
            $display("Error: Could not open output file.");
            $finish;
        end

        #20 rst = 0; // Release reset

        // PASS 1: Prime the Min/Max Tracker
        $display("Starting Pass 1 (Priming tracker)...");
        frame_start = 1;
        #10 frame_start = 0;

        for (int i = 0; i < TOTAL_PIXELS; i++) begin
            pixel_in = in_image_mem[i];
            #10; // Wait 1 clock cycle
        end

        // Wait for pipeline to flush
        #(PIPELINE_DELAY * 10); 

        // PASS 2: Process and Collect Valid Data
        $display("Starting Pass 2 (Processing image)...");
        frame_start = 1;
        #10 frame_start = 0;

        // Fork to inject pixels and capture output concurrently
        fork
            // Thread A: Feed pixels in
            begin
                for (int i = 0; i < TOTAL_PIXELS; i++) begin
                    pixel_in = in_image_mem[i];
                    #10;
                end
            end
            
            // Thread B: Capture delayed output
            begin
                #(PIPELINE_DELAY * 10); // Wait for the first valid pixel to exit
                for (int i = 0; i < TOTAL_PIXELS; i++) begin
                    $fdisplay(out_file, "%06X", pixel_out);
                    #10;
                end
            end
        join

        $display("Simulation Complete. Output saved to output_hex.txt");
        $fclose(out_file);
        $finish;
    end
endmodule