`timescale 1ns / 1ps

module IO_Assembly_Test_tb();
    // Test signals
    reg clk, rst;
    reg [15:0] switch;
    reg [3:0] button;
    wire [15:0] led;
    wire [7:0] tube_sel;
    wire [7:0] tube0, tube1;
    
    // CPU module instance
    CPU dut (
        .fpga_rst(rst),
        .fpga_clk(clk),
        .switch(switch),
        .button(button),
        .led(led),
        .tube_sel(tube_sel),
        .tube0(tube0),
        .tube1(tube1)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test script
    initial begin
        // Initialize
        rst = 1;
        switch = 16'h0000;
        button = 4'h0;
        
        // Reset the CPU
        #20 rst = 0;
        #20 rst = 1;
        
        // Wait for CPU to initialize
        #100;
        
        $display("Starting IO Assembly Test");
        
        // Simulate test case 000 - Input A from switch and display on LED
        $display("\nTest Case 000: Input A and display on LED");
        
        // Set switch value
        switch = 16'h00A5;
        #50;
        
        // Press Input A button (button[0])
        button[0] = 1;
        #100;
        button[0] = 0;
        #100;
        
        $display("Switch input: 0x%h, LED output: 0x%h", switch, led);
        
        // Change switch for input B
        switch = 16'h005A;
        #50;
        
        // Press Input B button (button[1])
        button[1] = 1;
        #100;
        button[1] = 0;
        #100;
        
        $display("Switch input: 0x%h, LED output: 0x%h", switch, led);
        
        // Simulate test case 001 - Load byte signed
        $display("\nTest Case 001: Load byte signed");
        
        // Set switch to test case 1
        switch = 16'h0001;
        #50;
        
        // Press test button (button[3])
        button[3] = 1;
        #100;
        button[3] = 0;
        #100;
        
        // Set switch value with high bit set to test sign extension
        switch = 16'h0085; // 10000101 binary
        #50;
        
        // Press input A button
        button[0] = 1;
        #100;
        button[0] = 0;
        #200;
        
        // Simulate test case 010 - Load byte unsigned
        $display("\nTest Case 010: Load byte unsigned");
        
        // Set switch to test case 2
        switch = 16'h0002;
        #50;
        
        // Press test button
        button[3] = 1;
        #100;
        button[3] = 0;
        #100;
        
        // Set switch value with high bit set to test zero extension
        switch = 16'h0085; // 10000101 binary - same as before
        #50;
        
        // Press input A button
        button[0] = 1;
        #100;
        button[0] = 0;
        #200;
        
        // Simulate test case 011 - Compare equality
        $display("\nTest Case 011: Compare equality");
        
        // Set switch to test case 3
        switch = 16'h0003;
        #50;
        
        // Press test button
        button[3] = 1;
        #100;
        button[3] = 0;
        #200;
        
        $display("LED output after comparison: 0x%h", led);
        
        // End simulation
        #200 $finish;
    end
    
    // Monitor for output changes
    always @(led) begin
        $display("Time %0t: LED changed to 0x%h", $time, led);
    end
    
    always @(tube0 or tube1) begin
        $display("Time %0t: 7-segment display changed", $time);
    end
endmodule