`timescale 1ns/1ps

module Digital_Clock_tb;

    // Testbench-controlled inputs to DUT
    logic clk = 0;
    logic SW_0 = 0;
    logic button_C = 0;
    logic button_M = 0;

    // Output from DUT
    logic [6:0] seg0, seg1, seg2, seg3, seg4, seg5;
    logic [7:0] LED;

    // Clock generation (50 MHz clock = 20ns period)
    always #10 clk = ~clk;

    // Instantiate the DUT
    Digital_Clock dut (
        // Inputs
        .clk(clk),
        .SW_0(SW_0),
        .button_C(button_C),
        .button_M(button_M),
        // Outputs
        .seg0(seg0),
        .seg1(seg1),
        .seg2(seg2),
        .seg3(seg3),
        .seg4(seg4),
        .seg5(seg5),
        .LED(LED)
    );

    // Stimulus block
    initial begin
        // Initial reset
        #40;
        button_C = 1;
        #40;
        button_C = 0;
        // testing SW_0 (enable)
        SW_0 = 1;
        #1000000;
        SW_0 = 0;
        #10000;
        SW_0 = 1;

        #1000000;
        // testing button_M (incrementing minute)
        button_M = 1;
        #10;
        button_M = 0;
        #1000000;
        button_M = 1;
        #10000;
        button_M = 0;

        #1000000;
        // testing button_C (reset clock)
        button_C = 1;
        #10000;
        button_C = 0;
        #1000000;
        button_M = 1;
        #10000;
        button_M = 0;
        #1000000;
        button_C = 1;
        #10000;
        button_C = 0;
        #1000000;

        $stop;

    end

endmodule