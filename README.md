# Digital Clock on FPGA,
This project implements a digital clock on an FPGA using Verilog. 

The clock displays time in HH:MM:SS format using 7-segment displays and includes buttons for resetting and incrementing minutes.

It also demonstrates how to debounce button inputs and control display multiplexing.

# Features
Time display in hours:minutes:seconds format.

Switch to enable/disable the clock.

Button to reset the clock.

Button to manually increment minutes.

Debounce modules for clean button input handling.

Multiplexed 7-segment display driver.

Seconds output mirrored on LEDs for debugging or visual aid.

# File Structure
top_module: The top-level module connecting all components.

digital_clock: Handles the internal timekeeping logic.

sevenseg_driver: Drives the 7-segment displays for time output.

debounce: Debounces the button inputs to avoid false triggers.

# Inputs
Name	       Type	     Description

clk	         Input	   Main FPGA clock signal

sw[0]	       Input	   Enable switch for the clock

button_C	   Input	   Reset button (clears the clock)

button_M	   Input	   Minute increment button

# Outputs
Name	       Type	     Description

seg[6:0]	   Output	   Segments for 7-segment displays

enanble	     Output	   Enables for each 7-segment digit

LED[7:0]	   Output	   Displays current seconds in binary

# Usage
Load the Verilog code into your FPGA development environment (e.g., Vivado, Quartus).

Connect appropriate hardware:

Clock input.

Two buttons for reset and minute increment.

One switch for clock enable.

6-digit 7-segment display.

8 LEDs for displaying seconds.

Program the FPGA and observe the working clock.

# Notes
The debounce module is essential for reliable button behavior.

Time is updated every second; hour overflow is handled internally.

The project can be extended to include alarms, time setting modes, or 12-hour/24-hour format switching.
