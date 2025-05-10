`timescale 1ns / 1ps

module Clock(
    input clk_in1,     // FPGA input clock
    input rst,         // Reset signal
    output clk_out1,   // CPU clock
    output clk_out2    // Slow display clock
);

    // Instantiate the clock wizard IP for CPU clock
    cpuclk clk_generator(
        .clk_in1(clk_in1),   // Input clock
        .clk_out1(clk_out1)  // Main CPU clock
    );
    
    // Implement a custom clock divider for display
    ClockDivider slow_clock(
        .clk_in(clk_in1),     // Input clock
        .rst(rst),            // Reset signal
        .clk_out(clk_out2)    // Output slow clock
    );

endmodule

module ClockDivider(
    input clk_in,      // Input clock
    input rst,         // Reset signal
    output reg clk_out // Output clock
);

    // Define a 2.5s period clock divider
    localparam COUNTER_MAX = 150000000; // For 2.5s at 100MHz input
    //localparam COUNTER_MAX = 5000;      // For simulation
    
    reg [31:0] counter;
    
    // Initialize the clock and counter
    initial begin
        clk_out = 1'b0;
        counter = 32'd0;
    end
    
    // Counter logic
    always @(posedge clk_in, negedge rst) begin
        if (~rst) begin
            counter <= 32'd0;
        end
        else if (counter >= COUNTER_MAX) begin
            counter <= 32'd0;
        end
        else begin
            counter <= counter + 32'd1;
        end
    end
    
    // Clock output generation
    always @(posedge clk_in, negedge rst) begin
        if (~rst) begin
            clk_out <= 1'b0;
        end
        else if (counter == COUNTER_MAX/2) begin
            clk_out <= 1'b1;  // Toggle at half period
        end
        else if (counter == COUNTER_MAX) begin
            clk_out <= 1'b0;  // Toggle at full period
        end
    end

endmodule