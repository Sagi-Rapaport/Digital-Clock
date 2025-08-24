# Digital Clock on FPGA (DE10-Lite)
This project implements a digital clock on an FPGA using SystemVerilog. 

The clock displays time in HH:MM:SS format using 7-segment displays and includes buttons for resetting and incrementing minutes.

# Features
- Time display in hours:minutes:seconds format.

- Switch to enable/disable the clock.

- Button to reset the clock.

- Button to manually increment minutes.

- Debounce modules for clean button input handling.

- Seconds output mirrored on LEDs for debugging or visual aid.

# File Structure
- Digital_Clock: The top-level module connecting all components.

- debounce: Debounces the button inputs to avoid false triggers. (including slow_clock_4Hz and D_FF modules)

- counter_and_display: Handles the internal timekeeping logic and responsible for presenting it through binary_to_BCD and decoder_7_segment modules.

# Inputs
Name  <--->   Description


- clk	 <--->	  Main FPGA clock signal (50 MHz)

- SW_0  <--->	  Enable switch for the clock

- button_C  <--->	 Reset button (clears the clock)

- button_M	<--->   Minute increment button

# Outputs
Name  <--->	  Description


- seg0[6:0], seg1[6:0], seg2[6:0], seg3[6:0], seg4[6:0], seg5[6:0]	 <--->  Segments for 7-segment displays (seg0[6:0] - right digit, seg5[6:0] - left digit)

- LED[7:0]	 <--->	 Displays current seconds with LEDs (LED[3:0] : 0-9 in binary, LED[4] : 10, LED[5] : 20, LED[6] : 30, LED[7] : OFF- max 59 seconds in clock)

# Usage
Load the SystemVerilog code into your FPGA development environment (e.g., Vivado, Quartus).

Connect appropriate hardware:

- Clock input.

- Two buttons for reset and minute increment.

- One switch for clock enable.

- 6-digit 7-segment display.

- 8 LEDs for displaying seconds.

Program the FPGA and observe the working Digital_Clock.

# Notes
- The debounce module is essential for reliable button behavior.

- Time is updated every second; hour overflow is handled internally.

- For FPGAs that have connection between all the 7-segments, there is option to utilize FSM and Multiplexing in the code.

- The project can be extended to include alarms, time setting modes, or 12-hour/24-hour format switching.
