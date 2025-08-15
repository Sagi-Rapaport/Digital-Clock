module Digital_Clock(
    input logic clk, // FPGA clock (50 MHz)
    input logic SW_0, // switch[0] to enable the clock
    input logic button_C, // reset the clock
    input logic button_M, // minute increment
    output logic [6:0] seg, // display the digit of 7 segment
    output logic [7:0] LED // display the seconds with LEDs
);

logic [5:0] enable;
logic [3:0] h2, h1, m2, m1, s2, s1;
logic min_up;

logic button_C_clr, button_M_clr;
logic button_C_clr_prev, button_M_clr_prev;

// instantiate the debounce module
debounce db_C(clk, button_C, button_C_clr); // reset button
debounce db_M(clk, button_M, button_M_clr); // minute up button

// instantiate the sevenseg_driver and counter modules
sevenseg_driver seg7(clk, s1, s2, m1, m2, h1, h2, seg, enable); // HH:MM:SS (from right to left)
counter clock(clk, SW_0, button_C_clr, min_up, s1, s2, m1, m2, h1, h2, LED);

// set the logic for the clock, minute up using the pushbutton
always_ff @(posedge clk) begin
    button_M_clr_prev <= button_M_clr; // minute up
    if (button_M_clr_prev == 1'b0 && button_M_clr == 1'b1) begin 
    // minute up button is zero and clr button is high then minute up is pressed, active
        min_up <= 1'b1;
    end
    else begin
        min_up <= 1'b0;
    end
end

endmodule

module debounce(
    input clk_in,
    input push_button,
    output signal_out 
);

logic clk_out; // slow clock
logic Q1, Q2, Q2_bar;

slow_clock_4Hz u1(clk_in, clk_out);
D_FF d1(clk_out, push_button, Q1);
D_FF d2(clk_out, Q1, Q2);

assign Q2_bar = !Q2;
assign signal_out = Q1 & Q2_bar;
    
endmodule

module slow_clock_4Hz( 
    input logic clk_in, // clock of the board (50 MHz)
    output logic clk_out // 4Hz slow clock
);

logic [22:0] count = 0; // 2^23 contain a number which is greater than 6.25 million

always_ff @(posedge clk_in) begin
    count <= count + 1;
    if (count == 6_250_000) begin
        count <= 0;
        clk_out <= !clk_out; // half of the cycle is on, half of the cycle is off
    end
end

endmodule

module D_FF( // 2 d flip flops for the right value sync with slow clock
    input clk, // input clock (slow clock)
    input D, // pushbutton
    output logic Q,
    output logic Qbar
);

always_ff @(posedge clk) begin
    Q <= D;
    Qbar <= !Q;
end

endmodule


module counter(
    input clk, 
    input enable,
    input reset,
    input min_up,
    output [3:0] s1,
    output [3:0] s2,
    output [3:0] m1,
    output [3:0] m2,
    output [3:0] h1,
    output [3:0] h2,
    output logic [7:0] LED
);

// time display: h2 h1 m2 m1 s2 s1
logic [5:0] min = 0, sec = 0; // 60 for min & sec (0-63)
logic [4:0] hour = 0; // 24 for hour (0-31)
logic [25:0] clk_counter = 0; // until 67 million

localparam one_sec = 50_000_000; // 1 sec

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        hour <= 0;
        min  <= 0;
        sec  <= 0;
    end
    else if (min_up) begin
         if (min == 6'd59)
             min <= 0;
         else 
             min <= min + 1;
    end
    // count part
    else if (enable) begin
        if (clk_counter == one_sec) begin
            clk_counter <= 0;
            if (sec == 6'd59) begin
                sec <= 0;
                if (min == 6'd59) begin
                    min <= 0;
                    if (hour == 6'd23)
                        hour <= 0;
                    else 
                        hour <= hour + 1;
                end
                else 
                     min <= min + 1;
            end
            else 
                sec <= sec + 1;
        end
        else 
            clk_counter <= clk_counter + 1;
    end
end

// instantiate the binary_to_BCD module
binary_to_BCD secs(.binary(sec), .tens(s2), .ones(s1));
binary_to_BCD mins(.binary(min), .tens(m2), .ones(m1));
binary_to_BCD hours(.binary(hour), .tens(h2), .ones(h1));

assign LED[7:0] = {s2, s1};

endmodule


module binary_to_BCD( 
    input logic [5:0] binary, // 6 bits input data that could come-in (0-63)
    output logic [3:0] tens, 
    output logic [3:0] ones 
);

logic [5:0] bcd_data;

always_comb begin 
    bcd_data = binary; 
    tens = bcd_data / 10; 
    ones = bcd_data % 10; 
end

endmodule


module decoder_7_segment(
    input logic [3:0] in, // 4 bits going into the segment
    output logic [6:0] seg // display the BCD number on a 7-segment
);

always_comb begin
    case (in)
        4'd0: seg = 7'b1000000; // active low logic
        4'd1: seg = 7'b1111001; // active low logic
        4'd2: seg = 7'b0100100; // active low logic
        4'd3: seg = 7'b0110000; // active low logic
        4'd4: seg = 7'b0011001; // active low logic
        4'd5: seg = 7'b0010010; // active low logic
        4'd6: seg = 7'b0000010; // active low logic
        4'd7: seg = 7'b1111000; // active low logic
        4'd8: seg = 7'b0000000; // active low logic
        4'd9: seg = 7'b0011000; // active low logic
        default: seg = 7'b0111111; // active low logic
    endcase
end

endmodule

module sevenseg_driver(
    input  logic clk, // main clock (50MHz)
    input  logic [3:0]  in1, // s1
    input  logic [3:0]  in2, // s2
    input  logic [3:0]  in3, // m1
    input  logic [3:0]  in4, // m2
    input  logic [3:0]  in5, // h1
    input  logic [3:0]  in6, // h2
    output logic [6:0]  seg // display the digit
);

logic [5:0] enable; // enable for every digit using FSM 
logic [6:0] seg1, seg2, seg3, seg4, seg5, seg6; // Local segment decoded outputs
logic [12:0] segclk; // Slow clock counter for multiplexing

// FSM state type
typedef enum logic [2:0] {
    RIGHT,     // s1
    RIGHT_L,   // s2
    MIDRIGHT,  // m1
    MIDLEFT,   // m2
    LEFT_R,    // h1
    LEFT       // h2
} state_t;

state_t state, next_state;

// Counter for multiplexing speed
always_ff @(posedge clk) begin
        segclk <= segclk + 1;
    end

// State register
always_ff @(posedge segclk[12]) begin
        state <= next_state;
    end

// Next-state & output logic
always_comb begin
    // Default values (safe defaults)
    seg     = 7'b1000000;
    enable  = 6'b000000;
    next_state = state;

    case (state)
        RIGHT: begin  // s1 - seconds (units)
            seg    = seg1;
            enable = 6'b111110; // the right 7 segment active
            next_state = RIGHT_L;
        end

        RIGHT_L: begin  // s2 - seconds (units)
            seg    = seg2;
            enable = 6'b111101; // the right-left 7 segment active
            next_state = MIDRIGHT;
        end

        MIDRIGHT: begin  // m1 - minutes (units)
            seg    = seg3;
            enable = 6'b111011; // the mid-right 7 segment active
            next_state = MIDLEFT;
        end

        MIDLEFT: begin  // m2 - minutes (units)
            seg    = seg4;
            enable = 6'b110111; // the mid-left 7 segment active
            next_state = LEFT_R;
        end

        LEFT_R: begin  // h1 - hours (units)
            seg    = seg5;
            enable = 6'b101111; // the left-right 7 segment active
            next_state = LEFT;
        end

        LEFT: begin  // h2 - hours (units)
            seg    = seg6;
            enable = 6'b011111; // the left 7 segment active
            next_state = RIGHT;
        end
    endcase
end

// Segment decoders for each digit
decoder_7_segment disp1(in1, seg1);
decoder_7_segment disp2(in2, seg2);
decoder_7_segment disp3(in3, seg3);
decoder_7_segment disp4(in4, seg4);
decoder_7_segment disp5(in5, seg5);
decoder_7_segment disp6(in6, seg6);

endmodule 