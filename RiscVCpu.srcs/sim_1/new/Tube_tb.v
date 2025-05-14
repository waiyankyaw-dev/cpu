`timescale 1ns / 1ps

module Tube_tb();
    // Test signals
    reg clk, fpgaClk, rst;
    reg ioWrite, tubeCtrl;
    reg [7:0] tubeAddr;
    reg [15:0] tubeWdata;
    reg [31:0] tubeWdata32;
    wire [7:0] sel, tube0, tube1;

    // Instantiate Tube module
    Tube uut (
        .clk(clk),
        .fpgaClk(fpgaClk),
        .rst(rst),
        .ioWrite(ioWrite),
        .tubeCtrl(tubeCtrl),
        .tubeAddr(tubeAddr),
        .tubeWdata(tubeWdata),
        .tubeWdata32(tubeWdata32),
        .sel(sel),
        .tube0(tube0),
        .tube1(tube1)
    );

    // Clock generation
    initial begin
        fpgaClk = 0;
        forever #5 fpgaClk = ~fpgaClk;  // 100MHz clock
    end

    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 50MHz clock
    end

    // Test stimulus
    initial begin
        // Initialize all signals
        rst = 0;          // Start with reset active low
        ioWrite = 0;
        tubeCtrl = 0;
        tubeAddr = 8'h60;
        tubeWdata = 16'h0000;
        tubeWdata32 = 32'h0;

        // Wait for 100ns for initial stabilization
        #100;
        
        // Release reset
        rst = 1;
        #100;

        // Test 1: Write 0x11112222
        tubeCtrl = 1;
        ioWrite = 1;
        tubeWdata32 = 32'h11112222;
        #500;  // Wait longer to see the effect

        // Test 2: Write different pattern
        tubeWdata32 = 32'hABCDEF01;
        #500;

        // Test 3: Write all zeros
        tubeWdata32 = 32'h00000000;
        #500;

        // End simulation
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t rst=%b sel=%b tube0=%b tube1=%b data=%h dispDat=%h",
                 $time, rst, sel, tube0, tube1, uut.data, uut.dispDat);
    end
endmodule