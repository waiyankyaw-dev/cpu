`timescale 1ns / 1ps

module IO_System_tb();
    // Test signals
    reg clk;
    reg rst;
    reg [15:0] switch;
    reg [3:0] button;
    reg [31:0] ALU_result;
    reg MemRead, MemWrite, IOReadUnsigned, IOReadSigned, IOWrite;
    reg [31:0] read_data_2;
    reg [31:0] ram_dat_o;
    
    wire [15:0] led;
    wire [7:0] tube_sel;
    wire [7:0] tube0;
    wire [7:0] tube1;
    wire [31:0] addr_out;
    wire [31:0] mem_data;
    wire [31:0] write_data;
    wire [31:0] write_data_32;
    wire LEDCtrl, SwitchCtrl, TubeCtrl;
    wire [15:0] io_rdata;
    
    // Instantiate the modules
    MemOrIO memory_io (
        .mRead(MemRead),
        .mWrite(MemWrite),
        .IOReadUnsigned(IOReadUnsigned),
        .IOReadSigned(IOReadSigned),
        .IOWrite(IOWrite),
        .addr_in(ALU_result),
        .addr_out(addr_out),
        .m_rdata(ram_dat_o),
        .io_rdata(io_rdata),
        .r_wdata(mem_data),
        .r_rdata(read_data_2),
        .write_data(write_data),
        .write_data_32(write_data_32),
        .LEDCtrl(LEDCtrl),
        .SwitchCtrl(SwitchCtrl),
        .TubeCtrl(TubeCtrl)
    );
    
    Switch switch_module (
        .clk(clk),
        .rst(rst),
        .IOReadUnsigned(IOReadUnsigned),
        .IOReadSigned(IOReadSigned),
        .SwitchCtrl(SwitchCtrl),
        .switch(switch),
        .button(button),
        .switchaddr(addr_out[7:0]),
        .switchrdata(io_rdata)
    );
    
    Led led_module (
        .clk(clk),
        .rst(rst),
        .IOWrite(IOWrite),
        .LEDCtrl(LEDCtrl),
        .ledaddr(addr_out[7:0]),
        .ledwdata(write_data[15:0]),
        .led(led)
    );
    
    // Test scenarios
    initial begin
        // Generate a clock signal
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    initial begin
        // Initialize signals
        rst = 0;
        switch = 16'h0000;
        button = 4'h0;
        ALU_result = 32'h00000000;
        MemRead = 0;
        MemWrite = 0;
        IOReadUnsigned = 0;
        IOReadSigned = 0;
        IOWrite = 0;
        read_data_2 = 32'h00000000;
        ram_dat_o = 32'h00000000;
        
        // Apply reset
        #10 rst = 1;
        #10 rst = 0;
        #10 rst = 1;
        
        // Testcase 1: Read from switches and display on LEDs
        $display("\nTestcase 1: Read from switches and display on LEDs");
        // Set switches
        switch = 16'hA5A5;
        
        // Read switches
        #10;
        ALU_result = 32'hfffffc00; // Address for all switches
        IOReadSigned = 1;
        #20; // Wait for two clock cycles for read to complete
        $display("Switches: 0x%h, IO read data: 0x%h", switch, io_rdata);
        
        // Write to LEDs
        IOReadSigned = 0;
        IOWrite = 1;
        ALU_result = 32'hfffffc30; // Address for all LEDs
        read_data_2 = {16'h0000, io_rdata}; // Use the read switch data
        #20; // Wait for two clock cycles for write to complete
        $display("Data written to LEDs: 0x%h, LED output: 0x%h", write_data[15:0], led);
        
        // Testcase 2: Button press simulation
        $display("\nTestcase 2: Button press simulation");
        // Set a button pressed
        button = 4'b0001; // Input A button
        
        // Read button state
        IOWrite = 0;
        IOReadUnsigned = 1;
        ALU_result = 32'hfffffc28; // Address for Input A button
        #20; // Wait for two clock cycles
        $display("Button state: 0x%h, IO read data: 0x%h", button, io_rdata);
        
        // Testcase 3: lb vs lbu instruction simulation
        $display("\nTestcase 3: lb vs lbu instruction simulation");
        // Set switch with high bit set
        switch = 16'h8040; // High bit set for signed/unsigned test
        
        // Read with lbu (unsigned)
        IOReadUnsigned = 1;
        IOReadSigned = 0;
        ALU_result = 32'hfffffc10; // Address for upper 8 switches
        #20;
        $display("Switches: 0x%h, lbu read: 0x%h", switch, mem_data);
        
        // Read with lb (signed)
        IOReadUnsigned = 0;
        IOReadSigned = 1;
        #20;
        $display("Switches: 0x%h, lb read: 0x%h", switch, mem_data);
        
        // End simulation
        #20 $finish;
    end
endmodule