module top_module(
    input clk, // FPGA clock
    input sw[0], // switch[0] to enable the clock
    input button_C, // reset the clock
    input button_M, // minute increment
    output [6:0] seg, 
    output [5:0] enanble,
    input [7:0] LED // display the seconds
);

wire [3:0] h2, h1, m2, m1, s2, s1;
reg min_up;

wire button_C_clr, button_M_clr;
reg button_C_clr_prev, button_M_clr_prev;

// instantiate the debounce module
debounce db_C(clk, button_C, button_C_clr); // reset button
debounce db_M(clk, button_M, button_M_clr); // minute up button

// instantiate the sevenseg_driver and digital clock modules
sevenseg_driver seg7(clk, 1'b0, h2, h1, m2, m1, s2, s1, seg, enable); // HH:MM:SS
digital_clock clock(clk, sw[0], button_C_clr, min_up, s1, s2, m1, m2, h1, h2);

// set the logic for the clock, minute up using the pushbutton
always @(posedge clk) begin
    button_M_clr_prev <= button_M_clr; // minute up
    if (button_M_clr_prev == 1'b0 && button_M_clr == 1'b1) begin
    // minute up button is zero and clr button is high then hour up is pressed, active
        min_up <= 1'b1;
    end
    else begin
        min_up <= 1'b0;
    end
end
    
    assign LED[7:0] = [S2, S1];

endmodule

module debounce(
    input clk_in,
    input push_button,
    output LED 
);

wire clk_out;
wire Q1, Q2, Q2_bar;

slow_clock_4Hz u1(clk_in, clk_out);
D_FF d1(clk_out, push_button, Q1);
D_FF d2(clk_out, Q1, Q2);

assign Q2_bar = !Q2;
assign LED = Q1 & Q2_bar;
    
endmodule

module slow_clock_4Hz( // clock on 50MHz
    input clk_in, // clock of the board (50MHz)
    output reg clk_out // 4Hz slow clock
);

reg [25:0] count = 0;

always @(posedge clk_in) begin
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
    output reg Q,
    output reg Qbar
);

always @(posedge clk) begin
    Q <= D;
    Qbar <= !Q;
end

endmodule


module digital_clock(
    input clk,
    input enanble,
    input reset,
    input min_up,
    output [3:0] s1,
    output [3:0] s2,
    output [3:0] m1,
    output [3:0] m2,
    output [3:0] h1,
    output [3:0] h2
);

// time display: h2 h1 m2 m1 s2 s1
reg [5:0] hour = 0, min = 0, sec = 0; // 60 for min & sec (0-63)
integer clk = 0;
localparam one_sec = 50_000_000 // 1 sec

always @(posedge clk) begin
    if (reset) begin
        [hour, min, sec] <= 0;
    end
    else if (min_up) begin
         if (min == 6'd59)
             min <= 0;
         else 
             min <= min + 1;
    end
    // count part
    else if (enanble) begin
        if (clk == one_sec) begin
            clk <= 0;
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
            clk <= clk + 1;
    end
end

binary_to_BCD secs(.binary(sec), .thousands(), .hundreds(), .tens(s2), .ones(s1));
binary_to_BCD mins(.binary(min), .thousands(), .hundreds(), .tens(m2), .ones(m1));
binary_to_BCD hours(.binary(hour), .thousands(), .hundreds(), .tens(h2), .ones(h1));

endmodule


module binary_to_BCD( // ? 0-11?
    input [11:0] binary, // 12 bits input data that could come-in
    output [3:0] thousands, 
    output [3:0] hundreds,
    output [3:0] tens,
    output [3:0] ones
);

reg [11:0] bcd_data = 0;

always @(binary) begin // example 1250
    bcd_data = binary; // 1250
    thousands = bcd_data / 1000; // 1250/1000 = 1
    bcd_data = bcd_data % 1000; // 1250%1000 = 250
    hundreds = bcd_data / 100; // 250/100 = 2
    bcd_data = bcd_data % 100; // 250%100 = 50
    tens = bcd_data / 10; // 50/10 = 5
    ones = bcd_data % 10; // 50%10 = 0
end

endmodule


module decoder_7_segment(
    input [3:0] in, // 4 bits going into the segment
    output reg [6:0] seg // display the BCD number on a 7-segment
);

always @(in) begin
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
    input clk,
    input clr,
    input [3:0] in1,
    input [3:0] in2,
    input [3:0] in3,
    input [3:0] in4,
    input [3:0] in5,
    input [3:0] in6,
    output reg [6:0] seg,
    output reg [5:0] enanble
);

wire [6:0] seg1, seg2, seg3, seg4, seg5, seg6;
reg [12:0] segclk; // for turning segment display one by one on the board

localparam RIGHT = 3'b000, RIGHT_L = 3'b001, MIDRIGHT = 3'b010, MIDLEFT = 3'b011, LEFT_R = 3'b100, LEFT = 3'b101;
reg [2:0] state = RIGHT;

always @(posedge clk) begin
    segclk <= segclk + 1; // the counter goes up by 1
end

always @(posedge segclk[12] or posedge clr) begin
    if (clr) begin
        seg <= 7'b1000000;
        enanble <= 6'b000000;
        state <= RIGHT;
    end
    else begin
        case (state)
        RIGHT: begin
            seg <= seg1;
            enanble <= 6'b111110;
            state <= RIGHT_L;
        end
        RIGHT_L: begin
            seg <= seg2;
            enanble <= 6'b111101;
            state <= MIDRIGHT;
        end
        MIDRIGHT: begin
            seg <= seg3;
            enanble <= 6'b111011;
            state <= MIDLEFT;
        end
        MIDLEFT: begin
            seg <= seg4;
            enanble <= 6'b110111;
            state <= LEFT_R;
        end
        LEFT_R: begin
            seg <= seg5;
            enanble <= 6'b101111;
            state <= LEFT;
        end
        LEFT: begin
            seg <= seg6;
            enanble <= 6'b011111;
            state <= RIGHT;
        end
        endcase
    end
    end

    decoder_7_segment disp1(in1, seg1);
    decoder_7_segment disp2(in2, seg2);
    decoder_7_segment disp3(in3, seg3);
    decoder_7_segment disp4(in4, seg4);
    decoder_7_segment disp5(in5, seg5);
    decoder_7_segment disp6(in6, seg6);

endmodule
        
    


