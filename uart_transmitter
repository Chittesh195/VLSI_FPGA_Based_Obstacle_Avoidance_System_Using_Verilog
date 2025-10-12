module uart_tx #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115200
)(
    input  wire clk,
    input  wire i_rst,
    input  wire i_start,
    input  wire [7:0] i_data,
    output wire o_tx,
    output wire o_busy
);
    localparam CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
    localparam DATA_BITS = 8;
    localparam IDLE = 2'b00,
              START_BIT = 2'b01,
              DATA_BITS_STATE = 2'b10,
              STOP_BIT = 2'b11;
    reg [1:0] r_state = IDLE;
    reg [7:0] r_tx_data;
    reg [$clog2(CLKS_PER_BIT)-1:0] r_clk_count = 0;
    reg [3:0] r_bit_index = 0; // Tracks current data bit (0-7)
    reg r_tx_pin = 1'b1; // UART transmit pin (active low for common anode? No, UART is logic level)

    always @(posedge clk) begin
        if (i_rst) begin
            r_state <= IDLE;
            r_clk_count <= 0;
            r_bit_index <= 0;
            r_tx_pin <= 1'b1;
        end else begin
            case (r_state)
                IDLE: begin
                    r_clk_count <= 0;
                    r_bit_index <= 0;
                    if (i_start) begin
                        r_tx_data <= i_data; // Latch input data
                        r_state <= START_BIT; // Transition to start bit
                        r_tx_pin <= 1'b0; // Start bit is low
                    end else begin
                        r_tx_pin <= 1'b1; // Idle: pin high
                    end
                end

                START_BIT: begin
                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1; // Hold start bit for CLKS_PER_BIT cycles
                    end else begin
                        // Start bit done; transition to data bits
                        r_clk_count <= 0;
                        r_state <= DATA_BITS_STATE;
                        r_tx_pin <= r_tx_data[r_bit_index + 1]; // First data bit (D0)
                    end
                end

                DATA_BITS_STATE: begin
                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1; // Hold current data bit
                    end else begin
                        // Current bit held; move to next bit or stop
                        r_clk_count <= 0;
                        if (r_bit_index < DATA_BITS - 1) begin // If not last bit (D7)
                            r_bit_index <= r_bit_index + 1; // Next bit index
                            r_tx_pin <= r_tx_data[r_bit_index]; // Update to next data bit
                        end else begin
                            // All data bits sent; transition to stop bit
                            r_state <= STOP_BIT;
                            r_tx_pin <= 1'b1; // Stop bit is high
                        end
                    end
                end

                STOP_BIT: begin
                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1; // Hold stop bit for CLKS_PER_BIT cycles
                    end else begin
                        // Stop bit done; return to idle
                        r_clk_count <= 0;
                        r_state <= IDLE;
                        r_tx_pin <= 1'b1; // Ensure pin is high in idle
                    end
                end

                default: begin
                    r_state <= IDLE; // Reset to idle on invalid state
                end
            endcase
        end
    end

    assign o_tx = r_tx_pin; // Transmit pin
    assign o_busy = (r_state != IDLE); // Busy when not in idle state
endmodule
