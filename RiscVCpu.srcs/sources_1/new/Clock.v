`timescale 1ns / 1ps

module Clock(
    input clkIn1,     // FPGA input clock
    input rst,        // Reset signal
    output clkOut1    // CPU clock
);

    // Instantiate the clock wizard IP for CPU clock
    cpuclk clkGenerator(
        .clk_in1(clkIn1),   // Input clock
        .clk_out1(clkOut1)  // Main CPU clock
    );

endmodule