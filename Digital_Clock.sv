module Digital_Clock(
    input logic clk, // FPGA clock (50 MHz)
    input logic SW_0, // switch[0] to enable the clock
    input logic button_C, // reset the clock
    input logic button_M, // minute increment
    output logic [6:0] seg0, seg1, seg2, seg3, seg4, seg5, // display of 6 digits on six 7-segments
    output logic [7:0] LED // display the seconds with LEDs
);

logic [3:0] h2, h1, m2, m1, s2, s1;
logic min_up;

logic button_C_clr, button_M_clr;
logic button_M_clr_prev;

// instantiate the debounce module
debounce db_C(clk, button_C, button_C_clr); // reset button
debounce db_M(clk, button_M, button_M_clr); // minute up button

// instantiate the counter_and_display modules 
counter_and_display clock(clk, SW_0, button_C_clr, min_up, seg0, seg1, seg2, seg3, seg4, seg5, LED); // HH:MM:SS (from right to left)

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


module counter_and_display(
    input clk, 
    input enable,
    input reset,
    input min_up,
    output [6:0] seg0,
    output [6:0] seg1,
    output [6:0] seg2,
    output [6:0] seg3,
    output [6:0] seg4,
    output [6:0] seg5,
    output logic [7:0] LED
);

// time display: h2 h1 m2 m1 s2 s1
logic [3:0] h2, h1, m2, m1, s2, s1;
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

// instantiate the decoder_7_segment module
decoder_7_segment disp1(s1, seg0);
decoder_7_segment disp2(s2, seg1);
decoder_7_segment disp3(m1, seg2);
decoder_7_segment disp4(m2, seg3);
decoder_7_segment disp5(h1, seg4);
decoder_7_segment disp6(h2, seg5);

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