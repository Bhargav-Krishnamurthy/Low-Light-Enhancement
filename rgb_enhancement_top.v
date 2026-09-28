module rgb_enhancement_top #(
    parameter IMG_WIDTH = 256
)(
    input clk,
    input rst,
    input frame_start,
    input [23:0] pixel_in,   // 24-bit RGB in
    output [23:0] pixel_out  // 24-bit RGB out
);

    // Split incoming 24-bit bus into R, G, B
    wire [7:0] r_in = pixel_in[23:16];
    wire [7:0] g_in = pixel_in[15:8];
    wire [7:0] b_in = pixel_in[7:0];

    // Wires to catch the processed 8-bit outputs
    wire [7:0] r_out, g_out, b_out;

    // Red Assembly Line
    image_enhancement_top #(
        .IMG_WIDTH(IMG_WIDTH)
    ) u_red_channel (
        .clk(clk), .rst(rst), .frame_start(frame_start),
        .pixel_in(r_in), .pixel_out(r_out)
    );

    // Green Assembly Line
    image_enhancement_top #(
        .IMG_WIDTH(IMG_WIDTH)
    ) u_green_channel (
        .clk(clk), .rst(rst), .frame_start(frame_start),
        .pixel_in(g_in), .pixel_out(g_out)
    );

    // Blue Assembly Line
    image_enhancement_top #(
        .IMG_WIDTH(IMG_WIDTH)
    ) u_blue_channel (
        .clk(clk), .rst(rst), .frame_start(frame_start),
        .pixel_in(b_in), .pixel_out(b_out)
    );

    // Pack the processed 8-bit signals back into a 24-bit bus
    assign pixel_out = {r_out, g_out, b_out};

endmodule