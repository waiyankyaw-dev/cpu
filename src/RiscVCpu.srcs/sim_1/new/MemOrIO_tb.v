`timescale 1ns / 1ps

module MemOrIO_tb();
    // Test signals
    reg mRead;
    reg mWrite;
    reg ioReadUnsigned;
    reg ioReadSigned;
    reg ioWrite;
    reg [31:0] addrIn;
    reg [31:0] mRdata;
    reg [15:0] ioRdata;
    reg [31:0] rRdata;
    
    wire [31:0] addrOut;
    wire [31:0] rWdata;
    wire [31:0] writeData;
    wire [31:0] writeData32;
    wire switchCtrl;
    wire ledCtrl;
    wire tubeCtrl;
    
    // Instantiate the MemOrIO module
    MemOrIO uut (
        .mRead(mRead),
        .mWrite(mWrite),
        .ioReadUnsigned(ioReadUnsigned),
        .ioReadSigned(ioReadSigned),
        .ioWrite(ioWrite),
        .addrIn(addrIn),
        .mRdata(mRdata),
        .ioRdata(ioRdata),
        .rRdata(rRdata),
        .addrOut(addrOut),
        .rWdata(rWdata),
        .writeData(writeData),
        .writeData32(writeData32),
        .switchCtrl(switchCtrl),
        .ledCtrl(ledCtrl),
        .tubeCtrl(tubeCtrl)
    );
    
    // Test scenarios
    initial begin
        // Initialize signals
        mRead = 0;
        mWrite = 0;
        ioReadUnsigned = 0;
        ioReadSigned = 0;
        ioWrite = 0;
        addrIn = 32'h00000000;
        mRdata = 32'h12345678;
        ioRdata = 16'hABCD;
        rRdata = 32'h87654321;
        
        // Test 1: Memory read
        $display("Test 1: Memory read");
        mRead = 1;
        addrIn = 32'h00001000; // Regular memory address
        #10;
        $display("Memory read at addr 0x%h, data: 0x%h", addrIn, rWdata);
        
        // Test 2: Memory write
        $display("Test 2: Memory write");
        mRead = 0;
        mWrite = 1;
        #10;
        $display("Memory write at addr 0x%h, data: 0x%h", addrIn, writeData);
        
        // Test 3: I/O read (unsigned) for switches
        $display("Test 3: I/O read (unsigned) for switches");
        mRead = 0;
        mWrite = 0;
        ioReadUnsigned = 1;
        addrIn = 32'hfffffc00; // Switch address
        ioRdata = 16'h80FF; // With high bit set
        #10;
        $display("I/O read unsigned at addr 0x%h, io_data: 0x%h, rWdata: 0x%h", 
                 addrIn, ioRdata, rWdata);
        $display("switchCtrl: %b, ledCtrl: %b, tubeCtrl: %b", switchCtrl, ledCtrl, tubeCtrl);
        
        // Test 4: I/O read (signed) for switches
        $display("Test 4: I/O read (signed) for switches");
        ioReadUnsigned = 0;
        ioReadSigned = 1;
        #10;
        $display("I/O read signed at addr 0x%h, io_data: 0x%h, rWdata: 0x%h", 
                 addrIn, ioRdata, rWdata);
        $display("switchCtrl: %b, ledCtrl: %b, tubeCtrl: %b", switchCtrl, ledCtrl, tubeCtrl);
        
        // Test 5: I/O write for LEDs
        $display("Test 5: I/O write for LEDs");
        ioReadSigned = 0;
        ioWrite = 1;
        addrIn = 32'hfffffc30; // LED address
        rRdata = 32'h0000FFFF;
        #10;
        $display("I/O write at addr 0x%h, rRdata: 0x%h, writeData: 0x%h", 
                 addrIn, rRdata, writeData);
        $display("switchCtrl: %b, ledCtrl: %b, tubeCtrl: %b", switchCtrl, ledCtrl, tubeCtrl);
        
        // Test 6: I/O write for Tube display
        $display("Test 6: I/O write for Tube display");
        addrIn = 32'hfffffc60; // Tube address
        #10;
        $display("I/O write at addr 0x%h, rRdata: 0x%h, writeData: 0x%h", 
                 addrIn, rRdata, writeData);
        $display("switchCtrl: %b, ledCtrl: %b, tubeCtrl: %b", switchCtrl, ledCtrl, tubeCtrl);
        
        // End simulation
        #10 $finish;
    end
endmodule