`timescale 1ns / 1ps

module Switch_tb();
    // Test signals
    reg clk;
    reg rst;
    reg ioReadUnsigned;
    reg ioReadSigned;
    reg switchCtrl;
    reg [15:0] switch;
    reg [3:0] button;
    reg [7:0] switchAddr;
    wire [15:0] switchRdata;
    
    // Instantiate the Switch module
    Switch uut (
        .clk(clk),
        .rst(rst),
        .ioReadUnsigned(ioReadUnsigned),
        .ioReadSigned(ioReadSigned),
        .switchCtrl(switchCtrl),
        .switch(switch),
        .button(button),
        .switchAddr(switchAddr),
        .switchRdata(switchRdata)
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
        ioReadUnsigned = 0;
        ioReadSigned = 0;
        switchCtrl = 0;
        switch = 16'h0000;
        button = 4'h0;
        switchAddr = 8'h00;
        
        // Apply reset
        #5 rst = 1;
        #20 rst = 0;
        #20 rst = 1;
        
        // Test 1: Read all 16 switches (address 0x00)
        $display("Test 1: Reading all 16 switches (address 0x00)");
        switch = 16'hA5A5; // Set switch value
        switchAddr = 8'h00;
        ioReadSigned = 1;
        switchCtrl = 1;
        #20;
        $display("Switches: 0x%h, Read data: 0x%h", switch, switchRdata);
        
        // Test 2: Read upper 8 switches (address 0x10)
        $display("Test 2: Reading upper 8 switches (address 0x10)");
        switch = 16'hBEEF;
        switchAddr = 8'h10;
        ioReadUnsigned = 1;
        ioReadSigned = 0;
        #20;
        $display("Switches: 0x%h, Read data: 0x%h", switch, switchRdata);
        
        // Test 3: Read buttons (addresses 0x20, 0x24, 0x28, 0x2C)
        $display("Test 3: Reading buttons");
        button = 4'b1010; // Set some buttons pressed
        // Test case button
        switchAddr = 8'h20;
        #20;
        $display("Buttons: 0x%h, Button 3 read: 0x%h", button, switchRdata);
        
        // Reset button
        switchAddr = 8'h24;
        #20;
        $display("Buttons: 0x%h, Button 2 read: 0x%h", button, switchRdata);
        
        // Input A button
        switchAddr = 8'h28;
        #20;
        $display("Buttons: 0x%h, Button 0 read: 0x%h", button, switchRdata);
        
        // Input B button
        switchAddr = 8'h2C;
        #20;
        $display("Buttons: 0x%h, Button 1 read: 0x%h", button, switchRdata);
        
        // Test 4: Disable switch control
        $display("Test 4: Disabled switch control");
        switchCtrl = 0;
        switch = 16'h1234;
        #20;
        $display("Switches: 0x%h, Read data: 0x%h (should remain unchanged)", switch, switchRdata);
        
        // End simulation
        #20 $finish;
    end
endmodule