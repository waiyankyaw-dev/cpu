`timescale 1ns / 1ps

module MemOrIO_tb();
    // Test signals
    reg mRead;
    reg mWrite;
    reg IOReadUnsigned;
    reg IOReadSigned;
    reg IOWrite;
    reg [31:0] addr_in;
    reg [31:0] m_rdata;
    reg [15:0] io_rdata;
    reg [31:0] r_rdata;
    
    wire [31:0] addr_out;
    wire [31:0] r_wdata;
    wire [31:0] write_data;
    wire [31:0] write_data_32;
    wire SwitchCtrl;
    wire LEDCtrl;
    wire TubeCtrl;
    
    // Instantiate the MemOrIO module
    MemOrIO uut (
        .mRead(mRead),
        .mWrite(mWrite),
        .IOReadUnsigned(IOReadUnsigned),
        .IOReadSigned(IOReadSigned),
        .IOWrite(IOWrite),
        .addr_in(addr_in),
        .m_rdata(m_rdata),
        .io_rdata(io_rdata),
        .r_rdata(r_rdata),
        .addr_out(addr_out),
        .r_wdata(r_wdata),
        .write_data(write_data),
        .write_data_32(write_data_32),
        .SwitchCtrl(SwitchCtrl),
        .LEDCtrl(LEDCtrl),
        .TubeCtrl(TubeCtrl)
    );
    
    // Test scenarios
    initial begin
        // Initialize signals
        mRead = 0;
        mWrite = 0;
        IOReadUnsigned = 0;
        IOReadSigned = 0;
        IOWrite = 0;
        addr_in = 32'h00000000;
        m_rdata = 32'h12345678;
        io_rdata = 16'hABCD;
        r_rdata = 32'h87654321;
        
        // Test 1: Memory read
        $display("Test 1: Memory read");
        mRead = 1;
        addr_in = 32'h00001000; // Regular memory address
        #10;
        $display("Memory read at addr 0x%h, data: 0x%h", addr_in, r_wdata);
        
        // Test 2: Memory write
        $display("Test 2: Memory write");
        mRead = 0;
        mWrite = 1;
        #10;
        $display("Memory write at addr 0x%h, data: 0x%h", addr_in, write_data);
        
        // Test 3: I/O read (unsigned) for switches
        $display("Test 3: I/O read (unsigned) for switches");
        mRead = 0;
        mWrite = 0;
        IOReadUnsigned = 1;
        addr_in = 32'hfffffc00; // Switch address
        io_rdata = 16'h80FF; // With high bit set
        #10;
        $display("I/O read unsigned at addr 0x%h, io_data: 0x%h, r_wdata: 0x%h", 
                 addr_in, io_rdata, r_wdata);
        $display("SwitchCtrl: %b, LEDCtrl: %b, TubeCtrl: %b", SwitchCtrl, LEDCtrl, TubeCtrl);
        
        // Test 4: I/O read (signed) for switches
        $display("Test 4: I/O read (signed) for switches");
        IOReadUnsigned = 0;
        IOReadSigned = 1;
        #10;
        $display("I/O read signed at addr 0x%h, io_data: 0x%h, r_wdata: 0x%h", 
                 addr_in, io_rdata, r_wdata);
        $display("SwitchCtrl: %b, LEDCtrl: %b, TubeCtrl: %b", SwitchCtrl, LEDCtrl, TubeCtrl);
        
        // Test 5: I/O write for LEDs
        $display("Test 5: I/O write for LEDs");
        IOReadSigned = 0;
        IOWrite = 1;
        addr_in = 32'hfffffc30; // LED address
        r_rdata = 32'h0000FFFF;
        #10;
        $display("I/O write at addr 0x%h, r_rdata: 0x%h, write_data: 0x%h", 
                 addr_in, r_rdata, write_data);
        $display("SwitchCtrl: %b, LEDCtrl: %b, TubeCtrl: %b", SwitchCtrl, LEDCtrl, TubeCtrl);
        
        // Test 6: I/O write for Tube display
        $display("Test 6: I/O write for Tube display");
        addr_in = 32'hfffffc60; // Tube address
        #10;
        $display("I/O write at addr 0x%h, r_rdata: 0x%h, write_data: 0x%h", 
                 addr_in, r_rdata, write_data);
        $display("SwitchCtrl: %b, LEDCtrl: %b, TubeCtrl: %b", SwitchCtrl, LEDCtrl, TubeCtrl);
        
        // End simulation
        #10 $finish;
    end
endmodule