// Verilog cannot find the log of a number, so we use the following technique:
// we store the log values of the numbers from 0 to 255 in a LUT and we can refer it to find the log values
module log_transform_lut (
    input clk,
    input [7:0] pixel_in,
    output reg [11:0] log_pixel_out // 12-bit output for precision
);
    reg [11:0] log_rom [0:255]; 

    initial begin
        $readmemh("log_values.mem", log_rom); 
    end

    always @(posedge clk) begin
        log_pixel_out <= log_rom[pixel_in]; 
    end
endmodule
