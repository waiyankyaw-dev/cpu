`timescale 1ns / 1ps

module CPU_Integrated_Test();
    // Top-level signals
    reg fpgaClk;
    reg fpgaRst;
    reg [15:0] switch;
    reg [3:0] button;
    wire [15:0] led;
    wire [7:0] tubeSel;
    wire [7:0] tube0, tube1;
    
    // CPU instantiation
    CPU dut (
        .fpgaClk(fpgaClk),
        .fpgaRst(fpgaRst),
        .switch(switch),
        .button(button),
        .led(led),
        .tubeSel(tubeSel),
        .tube0(tube0),
        .tube1(tube1)
    );
    
    // Define internal signals to monitor - these are defined based on hierarchical paths
    wire [31:0] currentPC = dut.iFetch.pc;
    wire [31:0] instruction = dut.inst;
    wire [31:0] aluResult = dut.aluResult;
    wire [31:0] readData1 = dut.readData1;
    wire [31:0] readData2 = dut.readData2;
    wire [31:0] memData = dut.memData;
    wire memRead = dut.memRead;
    wire memWrite = dut.memWrite;
    wire ioReadSigned = dut.ioReadSigned;
    wire ioReadUnsigned = dut.ioReadUnsigned;
    wire ioWrite = dut.ioWrite;
    wire regWrite = dut.regWrite;
    wire [31:0] addrOut = dut.addrOut;
    wire [31:0] writeData = dut.writeData;
    wire [31:0] ioRdata = {16'h0000, dut.ioRdata}; // Extend to 32 bits for display
    
    // Clock generation
    initial begin
        fpgaClk = 0;
        forever #5 fpgaClk = ~fpgaClk; // 100MHz clock
    end
    
    // Test scenarios
    initial begin
        // Initialize inputs
        fpgaRst = 0;
        switch = 16'h0000;
        button = 4'h0;
        
        // Apply reset sequence
        #20 fpgaRst = 1;
        #20 fpgaRst = 0;
        #20 fpgaRst = 1;
        
        // Wait for initialization
        #50;
        $display("CPU Reset Complete - Starting Execution");
        
        /* 
         * The simulation will now run the program that's loaded in the prgrom
         * We'll observe the execution and provide specific test inputs at key points
         */
        
        // Initial program should light all LEDs
        #200;
        $display("\n[Initialization] PC=%h, Inst=%h", currentPC, instruction);
        $display("All LEDs should be ON. LED=%h", led);
        
        // Wait for program to reach confirm_test state (waiting for reset button)
        #500;
        
        // Press reset button to proceed to test_case_input
        $display("\n[Test Setup] Pressing reset button");
        button[2] = 1;
        #100;
        button[2] = 0;
        #200;
        $display("All LEDs should be OFF. LED=%h", led);
        
        // Set test case selection to 0 (test000)
        $display("\n[Test Selection] Setting test case 0");
        switch = 16'h0000;
        #100;
        
        // Press test button to select test case
        button[3] = 1;
        #100;
        button[3] = 0;
        #200;
        $display("Selected test case 0. PC=%h, Inst=%h", currentPC, instruction);
        
        // Set input A value for test000
        $display("\n[Test 000 - Input A] Setting switch to 0xA5");
        switch = 16'h00A5;
        #100;
        
        // Press input A button
        button[0] = 1;
        #100;
        button[0] = 0;
        #200;
        $display("Input A processed. LED=%h, PC=%h", led, currentPC);
        
        // Set input B value for test000
        $display("\n[Test 000 - Input B] Setting switch to 0x5A");
        switch = 16'h005A;
        #100;
        
        // Press input B button
        button[1] = 1;
        #100;
        button[1] = 0;
        #200;
        $display("Input B processed. LED=%h, PC=%h", led, currentPC);
        
        // Press reset to return to test selection
        $display("\n[Test Reset] Pressing reset button");
        button[2] = 1;
        #100;
        button[2] = 0;
        #200;
        
        // Set test case selection to 1 (test001 - lb)
        $display("\n[Test Selection] Setting test case 1 (lb)");
        switch = 16'h0001;
        #100;
        
        // Press test button to select test case
        button[3] = 1;
        #100;
        button[3] = 0;
        #200;
        $display("Selected test case 1. PC=%h, Inst=%h", currentPC, instruction);
        
        // Set input value for test001 with high bit set
        $display("\n[Test 001 - lb] Setting switch to 0x85");
        switch = 16'h0085; // 10000101 binary - MSB set to test sign-extension
        #100;
        
        // Press input button
        button[0] = 1;
        #100;
        button[0] = 0;
        #200;
        
        // Observe the sign-extended result
        $display("lb instruction executed. PC=%h", currentPC);
        $display("Loaded value should be sign-extended from 0x85");
        $display("Display shows: %h", {dut.tubeModule.num7, dut.tubeModule.num6, dut.tubeModule.num5, dut.tubeModule.num4, 
                                      dut.tubeModule.num3, dut.tubeModule.num2, dut.tubeModule.num1, dut.tubeModule.num0});
        
        // Press reset to return to test selection
        $display("\n[Test Reset] Pressing reset button");
        button[2] = 1;
        #100;
        button[2] = 0;
        #200;
        
        // Set test case selection to 2 (test010 - lbu)
        $display("\n[Test Selection] Setting test case 2 (lbu)");
        switch = 16'h0002;
        #100;
        
        // Press test button to select test case
        button[3] = 1;
        #100;
        button[3] = 0;
        #200;
        $display("Selected test case 2. PC=%h, Inst=%h", currentPC, instruction);
        
        // Set same input value for test010
        $display("\n[Test 010 - lbu] Setting switch to 0x85");
        switch = 16'h0085; // Same value as before to compare sign/zero extension
        #100;
        
        // Press input button
        button[0] = 1;
        #100;
        button[0] = 0;
        #200;
        
        // Observe the zero-extended result
        $display("lbu instruction executed. PC=%h", currentPC);
        $display("Loaded value should be zero-extended from 0x85");
        $display("Display shows: %h", {dut.tubeModule.num7, dut.tubeModule.num6, dut.tubeModule.num5, dut.tubeModule.num4, 
                                      dut.tubeModule.num3, dut.tubeModule.num2, dut.tubeModule.num1, dut.tubeModule.num0});
        
        // Press reset to return to test selection
        $display("\n[Test Reset] Pressing reset button");
        button[2] = 1;
        #100;
        button[2] = 0;
        #200;
        
        // Set test case selection to 3 (test011 - beq)
        $display("\n[Test Selection] Setting test case 3 (beq comparison)");
        switch = 16'h0003;
        #100;
        
        // Press test button to select test case
        button[3] = 1;
        #100;
        button[3] = 0;
        #200;
        $display("Selected test case 3. PC=%h, Inst=%h", currentPC, instruction);
        
        // Observe the branch comparison result
        #300;
        $display("beq comparison executed. LED=%h", led);
        $display("LEDs should show comparison result (ON=equal, OFF=not equal)");
        
        // Press reset to return to test selection
        $display("\n[Test Reset] Pressing reset button");
        button[2] = 1;
        #100;
        button[2] = 0;
        #200;
        
        // Set test case selection to 6 (test110 - SLT)
        $display("\n[Test Selection] Setting test case 6 (SLT)");
        switch = 16'h0006;
        #100;
        
        // Press test button to select test case
        button[3] = 1;
        #100;
        button[3] = 0;
        #200;
        $display("Selected test case 6. PC=%h, Inst=%h", currentPC, instruction);
        
        // Observe the SLT instruction result
        #300;
        $display("SLT instruction executed. LED=%h", led);
        $display("LEDs should show SLT result");
        
        // Give time for complete execution
        #1000;
        
        // End simulation
        $display("\nIntegrated CPU Test Complete");
        $finish;
    end
    
    // Instruction decoder helper - for monitoring
    reg [5:0] instCount = 0;
    
    always @(instruction) begin
        instCount = instCount + 1;
        
        case(instruction[6:0])
            7'b0110011: $display("Inst %0d: R-type - %h", instCount, instruction);
            7'b0010011: $display("Inst %0d: I-type arithmetic - %h", instCount, instruction);
            7'b0000011: begin
                case(instruction[14:12])
                    3'b010: $display("Inst %0d: lw - %h", instCount, instruction);
                    3'b000: $display("Inst %0d: lb - %h", instCount, instruction);
                    3'b100: $display("Inst %0d: lbu - %h", instCount, instruction);
                    default: $display("Inst %0d: load other - %h", instCount, instruction);
                endcase
            end
            7'b0100011: $display("Inst %0d: sw - %h", instCount, instruction);
            7'b1100011: begin
                case(instruction[14:12])
                    3'b000: $display("Inst %0d: beq - %h", instCount, instruction);
                    3'b001: $display("Inst %0d: bne - %h", instCount, instruction);
                    3'b100: $display("Inst %0d: blt - %h", instCount, instruction);
                    3'b101: $display("Inst %0d: bge - %h", instCount, instruction);
                    3'b110: $display("Inst %0d: bltu - %h", instCount, instruction);
                    3'b111: $display("Inst %0d: bgeu - %h", instCount, instruction);
                    default: $display("Inst %0d: branch other - %h", instCount, instruction);
                endcase
            end
            7'b1101111: $display("Inst %0d: jal - %h", instCount, instruction);
            7'b1100111: $display("Inst %0d: jalr - %h", instCount, instruction);
            7'b0110111: $display("Inst %0d: lui - %h", instCount, instruction);
            default: $display("Inst %0d: unknown - %h", instCount, instruction);
        endcase
    end
    
    // Monitor key CPU state changes
    always @(posedge fpgaClk) begin
        if (regWrite)
            $display("RegWrite: rd=%d, data=%h", dut.decoder.writeReg, dut.decoder.writeData);
        
        if (memWrite)
            $display("MemWrite: addr=%h, data=%h", addrOut, readData2);
        
        if (memRead)
            $display("MemRead: addr=%h, data=%h", addrOut, memData);
            
        if (ioWrite)
            $display("IOWrite: addr=%h, data=%h", addrOut, writeData[15:0]);
            
        if (ioReadSigned || ioReadUnsigned)
            $display("IORead: addr=%h, data=%h, signed=%b, unsigned=%b", 
                     addrOut, ioRdata[15:0], ioReadSigned, ioReadUnsigned);
    end
    
    // Monitor LED changes
    always @(led) begin
        $display("LED changed to %h", led);
    end
    
    // Main monitoring output
    initial begin
        $monitor("Time=%0t, PC=%h, Inst=%h, ALU=%h", 
                 $time, currentPC, instruction, aluResult);
    end
endmodule