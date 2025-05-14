`timescale 1ns / 1ps

module Led_tb();
    // Test signals
    reg clk;
    reg rst;
    reg ioWrite;
    reg ledCtrl;
    reg [7:0] ledAddr;
    reg [15:0] ledWdata;
    wire [15:0] led;
    
    // Instantiate the LED module
    Led uut (
        .clk(clk),
        .rst(rst),
        .ioWrite(ioWrite),
        .ledCtrl(ledCtrl),
        .ledAddr(ledAddr),
        .ledWdata(ledWdata),
        .led(led)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50MHz clock
    end
    
    // Test scenarios
    initial begin
        // Initialize signals
        rst = 0;
        ioWrite = 0;
        ledCtrl = 0;
        ledAddr = 8'h00;
        ledWdata = 16'h0000;
        
        // Apply reset
        #5 rst = 1;
        #20 rst = 0;
        #20 rst = 1;
        
        // Test 1: Write to all LEDs (address 0x30)
        $display("Test 1: Write to all LEDs (address 0x30)");
        ledAddr = 8'h30;
        ledWdata = 16'hAAAA;
        ioWrite = 1;
        ledCtrl = 1;
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledWdata, led);
        
        // Test 2: Write to left 8 LEDs (address 0x40)
        $display("Test 2: Write to left 8 LEDs (address 0x40)");
        ledAddr = 8'h40;
        ledWdata = 16'h55FF;
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledWdata, led);
        
        // Test 3: Write to right 8 LEDs (address 0x50)
        $display("Test 3: Write to right 8 LEDs (address 0x50)");
        ledAddr = 8'h50;
        ledWdata = 16'hF0F0;
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledWdata, led);
        
        // Test 4: Write to individual LED (address 0x58)
        $display("Test 4: Write to individual LED (address 0x58)");
        ledAddr = 8'h58;
        ledWdata = 16'h0001; // Turn on LED 0
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledWdata, led);
        
        // Test 5: Write to individual LED (address 0x59)
        $display("Test 5: Write to individual LED (address 0x59)");
        ledAddr = 8'h59;
        ledWdata = 16'h0001; // Turn on LED 1
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledWdata, led);
        
        // Test 6: Disable LED control
        $display("Test 6: Disabled LED control");
        ledCtrl = 0;
        ledAddr = 8'h30;
        ledWdata = 16'h9999;
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h (should remain unchanged)", ledWdata, led);
        
        // End simulation
        #20 $finish;
    end
endmodule