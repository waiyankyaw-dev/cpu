`timescale 1ns / 1ps

module Tube_tb();
    // Test signals
    reg clk, fpga_clk, rst;
    reg clk_div_2s, button, button2;
    reg IOWrite, TubeCtrl;
    reg [7:0] tubeaddr;
    reg [15:0] tubewdata;
    reg [31:0] tubewdata32;
    reg [15:0] testcase;
    wire [7:0] sel, tube0, tube1;

    // Instantiate Tube module
    Tube uut (
        .clk(clk),
        .fpga_clk(fpga_clk),
        .rst(rst),
        .clk_div_2s(clk_div_2s),
        .button(button),
        .button2(button2),
        .IOWrite(IOWrite),
        .TubeCtrl(TubeCtrl),
        .tubeaddr(tubeaddr),
        .tubewdata(tubewdata),
        .tubewdata32(tubewdata32),
        .testcase(testcase),
        .sel(sel),
        .tube0(tube0),
        .tube1(tube1)
    );

    // Clock generation
    initial begin
        fpga_clk = 0;
        forever #5 fpga_clk = ~fpga_clk;  // 100MHz clock
    end

    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 50MHz clock
    end

    // Test stimulus
    initial begin
        // Initialize all signals
        rst = 0;          // Start with reset active low
        IOWrite = 0;
        TubeCtrl = 0;
        tubeaddr = 8'h60;
        tubewdata = 16'h0000;
        tubewdata32 = 32'h0;
        testcase = 16'h0;
        button = 0;
        button2 = 0;
        clk_div_2s = 0;

        // Wait for 100ns for initial stabilization
        #100;
        
        // Release reset
        rst = 1;
        #100;

        // Test 1: Write 0x12345678
        TubeCtrl = 1;
        IOWrite = 1;
        tubewdata32 = 32'h11112222;
        #500;  // Wait longer to see the effect

        // Test 2: Write 0xABCDEF01
        tubewdata32 = 32'h11112222;
        #500;

        // Test 3: Write 0x00000000
        tubewdata32 = 32'h00000000;
        #500;

        // End simulation
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t rst=%b sel=%b tube0=%b tube1=%b data=%h disp_dat=%h",
                 $time, rst, sel, tube0, tube1, uut.data, uut.disp_dat);
    end

endmodule