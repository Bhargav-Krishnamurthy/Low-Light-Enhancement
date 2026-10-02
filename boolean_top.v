`timescale 1ns / 1ps
module boolean_top (
    input  wire        clk,          // Pin F14 
    input  wire        rst,          // Pin J2 (BTN0)
    input  wire        btn1,         // Pin J1 (Frame Start Trigger)
    input  wire        rx,           
    output wire        tx,           
    output wire [15:0] led           
);
    // Button Debounce and Sync
    reg rst_sync1=1, rst_sync2=1;
    reg btn1_sync1=0, btn1_sync2=0, btn1_sync3=0;
    always @(posedge clk) begin
        rst_sync1 <= rst; rst_sync2 <= rst_sync1;
        btn1_sync1 <= btn1; btn1_sync2 <= btn1_sync1; btn1_sync3 <= btn1_sync2;
    end
    wire frame_start = btn1_sync2 & ~btn1_sync3; // 1-clock pulse on press

    // UART RX
    wire [7:0] rx_byte;
    wire rx_done;
    uart_rx #(.CLK_FREQ(100000000), .BAUD_RATE(115200)) u_rx (.clk(clk), .rst(rst_sync2), .rx(rx), .rx_data(rx_byte), .rx_valid(rx_done));

    // RX State Machine (Packs 3 UART bytes into 24-bit RGB)
    reg [1:0] rx_byte_cnt = 0;
    reg [23:0] rgb_in;
    reg valid_to_pipeline = 0;

    always @(posedge clk) begin
        if (rst_sync2) begin
            rx_byte_cnt <= 0;
            valid_to_pipeline <= 0;
        end else begin
            valid_to_pipeline <= 1'b0;
            if (rx_done) begin
                if (rx_byte_cnt == 0) rgb_in[23:16] <= rx_byte;
                if (rx_byte_cnt == 1) rgb_in[15:8]  <= rx_byte;
                if (rx_byte_cnt == 2) begin
                    rgb_in[7:0] <= rx_byte;
                    valid_to_pipeline <= 1'b1;
                end
                rx_byte_cnt <= (rx_byte_cnt == 2) ? 0 : rx_byte_cnt + 1;
            end
        end
    end

    // Image Enhancement Pipeline
    wire [23:0] rgb_out;
    wire valid_from_pipeline;
    rgb_enhancement_top #(.IMG_WIDTH(256)) u_image_pipeline (
        .clk(clk), .rst(rst_sync2), .valid_in(valid_to_pipeline),
        .frame_start(frame_start), .pixel_in(rgb_in),
        .pixel_out(rgb_out), .valid_out(valid_from_pipeline)
    );

    // UART TX and Edge Detector
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_busy;
    reg tx_busy_d;
    
    always @(posedge clk) tx_busy_d <= tx_busy;
    wire tx_done_pulse = ~tx_busy & tx_busy_d; 

    uart_tx #(.CLK_FREQ(100000000), .BAUD_RATE(115200)) u_tx (.clk(clk), .rst(rst_sync2), .tx_start(tx_start), .tx_data(tx_data), .tx(tx), .tx_busy(tx_busy));

    // TX State Machine (Unpacks 24-bit RGB to 3 UART bytes)
    localparam TX_IDLE = 0, TX_SEND_R = 1, TX_SEND_G = 2, TX_SEND_B = 3;
    reg [2:0] tx_state = TX_IDLE;
    reg [23:0] tx_buffer;

    always @(posedge clk) begin
        if (rst_sync2) begin
            tx_state <= TX_IDLE;
            tx_start <= 0;
        end else begin
            tx_start <= 0; 
            case (tx_state)
                TX_IDLE: begin
                    if (valid_from_pipeline) begin
                        tx_buffer <= rgb_out;
                        tx_data   <= rgb_out[23:16];
                        tx_start  <= 1'b1;
                        tx_state  <= TX_SEND_R;
                    end
                end
                TX_SEND_R: begin
                    if (tx_done_pulse) begin 
                        tx_data  <= tx_buffer[15:8];
                        tx_start <= 1'b1;
                        tx_state <= TX_SEND_G;
                    end
                end
                TX_SEND_G: begin
                    if (tx_done_pulse) begin 
                        tx_data  <= tx_buffer[7:0];
                        tx_start <= 1'b1;
                        tx_state <= TX_SEND_B;
                    end
                end
                TX_SEND_B: begin
                    if (tx_done_pulse) tx_state <= TX_IDLE;
                end
            endcase
        end
    end

    // Diagnostic LEDs
    assign led[15] = btn1_sync2;       // Illuminates when Frame Start is pressed
    assign led[14] = rst_sync2;        
    assign led[13:8] = 0;
    assign led[7:0] = rgb_out[23:16];  // Displays processed Red channel
endmodule