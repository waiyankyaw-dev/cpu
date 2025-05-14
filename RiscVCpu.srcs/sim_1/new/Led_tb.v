`timescale 1ns / 1ps

module Led_tb();
    // Test signals
    reg clk;
    reg rst;
    reg IOWrite;
    reg LEDCtrl;
    reg [7:0] ledaddr;
    reg [15:0] ledwdata;
    wire [15:0] led;
    
    // Instantiate the LED module
    Led uut (
        .clk(clk),
        .rst(rst),
        .IOWrite(IOWrite),
        .LEDCtrl(LEDCtrl),
        .ledaddr(ledaddr),
        .ledwdata(ledwdata),
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
        IOWrite = 0;
        LEDCtrl = 0;
        ledaddr = 8'h00;
        ledwdata = 16'h0000;
        
        // Apply reset
        #5 rst = 1;
        #20 rst = 0;
        #20 rst = 1;
        
        // Test 1: Write to all LEDs (address 0x30)
        $display("Test 1: Write to all LEDs (address 0x30)");
        ledaddr = 8'h30;
        ledwdata = 16'hAAAA;
        IOWrite = 1;
        LEDCtrl = 1;
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledwdata, led);
        
        // Test 2: Write to left 8 LEDs (address 0x40)
        $display("Test 2: Write to left 8 LEDs (address 0x40)");
        ledaddr = 8'h40;
        ledwdata = 16'h55FF;
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledwdata, led);
        
        // Test 3: Write to right 8 LEDs (address 0x50)
        $display("Test 3: Write to right 8 LEDs (address 0x50)");
        ledaddr = 8'h50;
        ledwdata = 16'hF0F0;
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledwdata, led);
        
        // Test 4: Write to individual LED (address 0x58)
        $display("Test 4: Write to individual LED (address 0x58)");
        ledaddr = 8'h58;
        ledwdata = 16'h0001; // Turn on LED 0
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledwdata, led);
        
        // Test 5: Write to individual LED (address 0x59)
        $display("Test 5: Write to individual LED (address 0x59)");
        ledaddr = 8'h59;
        ledwdata = 16'h0001; // Turn on LED 1
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h", ledwdata, led);
        
        // Test 6: Disable LED control
        $display("Test 6: Disabled LED control");
        LEDCtrl = 0;
        ledaddr = 8'h30;
        ledwdata = 16'h9999;
        #20;
        $display("LED data written: 0x%h, LED output: 0x%h (should remain unchanged)", ledwdata, led);
        
        // End simulation
        #20 $finish;
    end
endmodule