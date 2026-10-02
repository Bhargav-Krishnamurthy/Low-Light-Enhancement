
module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,

    // Asynchronous UART input
    input  wire       rx,

    // Received byte
    output reg [7:0] rx_data,

    // Goes HIGH for one clock cycle when a byte is received
    output reg       rx_valid
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE; 
    localparam integer HALF_BIT = CLKS_PER_BIT / 2; 

    // synchronising
    reg rx_sync1;
    reg rx_sync2;
    
    // we do this to prevent metastability
    always @(posedge clk) begin
        if (rst) begin
            rx_sync1 <= 0;
            rx_sync2 <= 0;
        end
        else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end
    // These are the states :
    // IDLE: Waiting for RX to become LOW.
    // START: We detected a possible start bit. Wait HALF_BIT clocks and verify RX is still LOW.
    // DATA: Sample 8 data bits.
    // STOP: Wait one bit period and verify STOP bit.
    // DONE: A byte has been received.

    localparam [2:0] IDLE  = 3'd0, START = 3'd1, DATA  = 3'd2, STOP  = 3'd3, DONE  = 3'd4;
    reg [2:0] state;

    // Counts FPGA clock cycles within one UART bit.
    // Example: 0, 1, 2, 3, ... 867
    // then reset back to 0.
    reg [15:0] baud_counter;
    
    // Keeps track of which data bit we're currently receiving.
    // Should count: 0 -> 1 -> 2 -> ... -> 7
    reg [2:0] bit_counter;

    // Temporary register where received bits are accumulated.
    reg [7:0] rx_shift_reg;

// The main FSM Block
    always @(posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            baud_counter <= 16'd0;
            bit_counter  <= 3'd0;
            rx_shift_reg <= 8'd0;
            rx_data      <= 8'd0;
            rx_valid     <= 1'b0;
        end
        else begin
            rx_valid <= 1'b0;
            case (state)
                IDLE: begin
                    if (rx_sync2 == 0) begin
                        // Start counting clocks.
                        baud_counter <= 0;
                        state <= START;
                    end

                end

                START: begin
                    if (baud_counter == HALF_BIT - 1) begin
                        if (rx_sync2 == 0) begin
                            baud_counter <= 0;
                            bit_counter  <= 0;
                            state        <= DATA;
                        end
                        else begin
                            state <= IDLE;
                        end

                    end
                    else begin
                        baud_counter <= baud_counter + 1;
                    end

                end

                DATA: begin
                    if (baud_counter == CLKS_PER_BIT - 1) begin
                        rx_shift_reg[bit_counter] <= rx_sync2;
                        baud_counter <= 0;
                        if (bit_counter == 3'b111) begin
                            state <= STOP;
                        end
                        else begin
                            bit_counter <= bit_counter+1;
                        end
                    end
                    else begin
                        baud_counter <= baud_counter + 1;
                    end

                end
                
                
                
                STOP: begin
                    if (baud_counter == CLKS_PER_BIT - 1) begin
                        if (rx_sync2 == 1) begin
                            rx_data <= rx_shift_reg;
                            rx_valid <= 1;
                            state <= IDLE;

                        end
                        else begin
                            state <= IDLE;

                        end

                    end
                    else begin

                        baud_counter <= baud_counter + 1;
                    end

                end


                DONE: begin
                    state <= IDLE;

                end


                default: begin
                    state <= IDLE;
                end

            endcase

        end
    end

endmodule
