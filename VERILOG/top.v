module project_top (
    // Physical Inputs/Outputs
    input  wire         clk,
    input  wire         reset,

    // Ultrasonic Sensor Interface
    output wire         trig,
    input  wire         echo,

    // 7-Segment Display Interface
    output wire [6:0]   seg,
    output wire [3:0]   an,

    // BCD Debug Outputs (connected to LEDs)
    output wire [3:0]   cm0, // Ones digit
    output wire [3:0]   cm1, // Tens digit

    // UART Interface to ESP32
    output wire         uart_tx_pin
);

    //================================================================
    // Internal Signals for Connecting Modules
    //================================================================
    wire        uart_busy;
    wire [7:0]  new_distance;

    reg         send_trigger;
    reg  [7:0]  distance_binary;
    reg  [3:0]  prev_cm0;
    reg  [3:0]  prev_cm1;

    //================================================================
    // BCD to Binary Conversion
    //================================================================
    assign new_distance = (cm1 * 10) + cm0;

    //================================================================
    // 1. Instantiate Sonar Module
    //================================================================
    sonar sonar_inst (
        .clk        (clk),
        .trig       (trig),
        .echo       (echo),
        .cm1        (cm1),
        .cm0        (cm0),
        .seg        (seg),
        .an         (an)
    );

    //================================================================
    // 2. Instantiate UART Transmitter Module
    //================================================================
    uart_tx #(
        .CLOCK_FREQ (100_000_000),
        .BAUD_RATE  (115200)
    ) uart_inst (
        .clk        (clk),
        .i_rst      (reset),
        .i_start    (send_trigger),
        .i_data     (distance_binary),
        .o_tx       (uart_tx_pin),
        .o_busy     (uart_busy)
    );

    //================================================================
    // 3. Glue Logic (Manages UART Transmission)
    //================================================================
    always @(posedge clk) begin
        // Store the current BCD values to detect a change in the next cycle.
        prev_cm0 <= cm0;
        prev_cm1 <= cm1;

        // Default the trigger to low.
        send_trigger <= 1'b0;

        // Check if the distance has changed and the UART is not busy.
        if ((cm0 != prev_cm0 || cm1 != prev_cm1) && !uart_busy) begin
            // A change was detected!
            distance_binary <= new_distance;
            send_trigger <= 1'b1;
        end
    end

endmodule
