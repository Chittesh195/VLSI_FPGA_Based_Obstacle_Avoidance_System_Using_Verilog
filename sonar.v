module sonar (
    input  wire clk,
    output reg  trig,                      // trigger
    input  wire echo,                      // echo
    output reg [3:0] cm1,                  // tens digit (BCD)
    output reg [3:0] cm0,                  // ones digit (BCD)
    output reg [6:0] seg,                  // 7-segment display segments (a-g)
    output reg [3:0] an                    // 7-segment display digit select
);

    // Clock divider for display refresh
    reg [16:0] clk_div = 17'd0;

    // Display signals
    reg [3:0] display_digit = 4'd0;
    reg [1:0] digit_sel = 2'd0;

    // Distance registers (to hold BCD values)
    reg [3:0] dist_ones = 4'd0;
    reg [3:0] dist_tens = 4'd0;

    // Registered outputs
    reg [3:0] cm0_reg = 4'd0;
    reg [3:0] cm1_reg = 4'd0;
    reg [6:0] seg_reg = 7'b1111111;
    reg [3:0] an_reg  = 4'b1111;

    // Echo synchronization
    reg [2:0] echo_sync = 3'b000;
    reg echo_synced = 1'b0;
    reg prev_echo_synced = 1'b0;

    // Edge detection
    reg echo_rising = 1'b0;
    reg echo_falling = 1'b0;

    // Constants for timing
    localparam TRIG_DURATION        = 500;       // 10 us trigger pulse (50MHz)
    localparam COUNTS_PER_CM        = 2900;      // clock cycles per cm
    localparam TIMEOUT_COUNT        = 700000;    // timeout ~14ms
    localparam MEASUREMENT_INTERVAL = 1250000;   // ~25ms between measurements

    // State machine encoding
    localparam IDLE            = 3'd0,
               TRIGGER         = 3'd1,
               WAIT_ECHO_START = 3'd2,
               WAIT_ECHO_END   = 3'd3,
               UPDATE          = 3'd4,
               COOLDOWN        = 3'd5;

    reg [2:0] state = IDLE;

    // Counters
    integer distance_counter = 0;
    integer measurement_counter = 0;
    reg reading_valid = 1'b0;
    integer reset_counter = 0;

    // Assign outputs
    always @(*) begin
        cm0 = cm0_reg;
        cm1 = cm1_reg;
        seg = seg_reg;
        an  = an_reg;
    end

    // Main sonar process
    always @(posedge clk) begin
        // Synchronize echo
        echo_sync <= {echo_sync[1:0], echo};
        prev_echo_synced <= echo_synced;
        echo_synced <= echo_sync[2];

        // Edge detection
        echo_rising  <= (echo_synced & ~prev_echo_synced);
        echo_falling <= (~echo_synced & prev_echo_synced);

        case (state)
            IDLE: begin
                trig <= 1'b0;
                distance_counter <= 0;
                reading_valid <= 1'b0;
                measurement_counter <= 0;
                state <= TRIGGER;
            end

            TRIGGER: begin
                if (measurement_counter < TRIG_DURATION) begin
                    trig <= 1'b1;
                    measurement_counter <= measurement_counter + 1;
                end else begin
                    trig <= 1'b0;
                    measurement_counter <= 0;
                    state <= WAIT_ECHO_START;
                end
            end

            WAIT_ECHO_START: begin
                if (echo_rising) begin
                    distance_counter <= 0;
                    state <= WAIT_ECHO_END;
                    measurement_counter <= 0;
                end else if (measurement_counter > TIMEOUT_COUNT) begin
                    cm0_reg <= 4'b0000;
                    cm1_reg <= 4'b0000;
                    dist_ones <= 4'b0000;
                    dist_tens <= 4'b0000;
                    reading_valid <= 1'b0;
                    state <= COOLDOWN;
                end else begin
                    measurement_counter <= measurement_counter + 1;
                end
            end

            WAIT_ECHO_END: begin
                if (echo_falling) begin
                    reading_valid <= 1'b1;
                    state <= UPDATE;
                end else if (measurement_counter > TIMEOUT_COUNT) begin
                    reading_valid <= 1'b0;
                    state <= COOLDOWN;
                end else begin
                    measurement_counter <= measurement_counter + 1;
                    if (distance_counter >= COUNTS_PER_CM) begin
                        distance_counter <= 0;
                        if (dist_ones == 4'd9) begin
                            if (dist_tens == 4'd9) begin
                                dist_ones <= 4'd9;
                                dist_tens <= 4'd9;
                            end else begin
                                dist_ones <= 4'd0;
                                dist_tens <= dist_tens + 1;
                            end
                        end else begin
                            dist_ones <= dist_ones + 1;
                        end
                    end else begin
                        distance_counter <= distance_counter + 1;
                    end
                end
            end

            UPDATE: begin
                if (reading_valid) begin
                    cm0_reg <= dist_ones;
                    cm1_reg <= dist_tens;
                end
                measurement_counter <= 0;
                state <= COOLDOWN;
            end

            COOLDOWN: begin
                if (measurement_counter < MEASUREMENT_INTERVAL) begin
                    measurement_counter <= measurement_counter + 1;
                end else begin
                    dist_ones <= 4'b0000;
                    dist_tens <= 4'b0000;
                    if (reset_counter < 10)
                        reset_counter <= reset_counter + 1;
                    else begin
                        reset_counter <= 0;
                        if (!reading_valid) begin
                            cm0_reg <= 4'b0000;
                            cm1_reg <= 4'b0000;
                        end
                    end
                    state <= IDLE;
                end
            end
        endcase
    end

// Declare outside
reg [6:0] seg_pattern;
reg [3:0] an_pattern;

// 7-segment display controller
always @(posedge clk) begin
    clk_div <= clk_div + 1;
    digit_sel <= clk_div[16:15];

    case (digit_sel)
        2'b00: begin
            display_digit <= cm0_reg;
            an_pattern = 4'b1110;
        end
        2'b01: begin
            display_digit <= cm1_reg;
            an_pattern = 4'b1101;
        end
        2'b10: begin
            display_digit <= 4'b0000;
            an_pattern = 4'b1111;
        end
        default: begin
            display_digit <= 4'b0000;
            an_pattern = 4'b1111;
        end
    endcase

    case (display_digit)
        4'd0: seg_pattern = 7'b1000000;
        4'd1: seg_pattern = 7'b1111001;
        4'd2: seg_pattern = 7'b0100100;
        4'd3: seg_pattern = 7'b0110000;
        4'd4: seg_pattern = 7'b0011001;
        4'd5: seg_pattern = 7'b0010010;
        4'd6: seg_pattern = 7'b0000010;
        4'd7: seg_pattern = 7'b1111000;
        4'd8: seg_pattern = 7'b0000000;
        4'd9: seg_pattern = 7'b0010000;
        default: seg_pattern = 7'b0111111;
    endcase

    seg_reg <= seg_pattern;
    an_reg  <= an_pattern;
end

endmodule
