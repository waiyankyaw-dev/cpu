`timescale 1ns / 1ps

module CPU(
    input fpga_rst,               // FPGA reset button
    input fpga_clk,               // FPGA clock
    input [15:0] switch,          // 16 DIP switches
    input [3:0] button,           // 4 push buttons
    
    output [15:0] led,            // 16 LEDs
    output [7:0] tube_sel,        // 7-segment display digit select
    output [7:0] tube0,           // 7-segment display upper segments
    output [7:0] tube1            // 7-segment display lower segments
);

    // Internal signal declarations
    wire cpu_clk;                 // CPU clock
    wire clk_div_2s;              // Slow 2.5s clock
    wire rst;                     // Reset signal
    
    // Instruction fetch signals
    wire [31:0] inst;             // Current instruction
    wire [31:0] imm32;            // Immediate value
    
    // ALU and branch control signals
    wire zero, negative, unsigned_less;
    wire [31:0] ALU_result;       // ALU result
    wire [1:0] ALUOp;             // ALU operation select
    wire ALUSrc;                  // ALU source select (reg/imm)
    
    // Register and memory signals
    wire [31:0] read_data_1;      // Register source 1
    wire [31:0] read_data_2;      // Register source 2
    wire [31:0] write_data;       // Data for memory/IO write
    wire [31:0] write_data_32;    // Full 32-bit data for IO
    wire [31:0] addr_out;         // Memory/IO address
    wire [31:0] ram_dat_o;        // Data from memory
    wire [31:0] mem_data;         // Data to register file
    
    // Control signals
    wire MemRead, MemWrite;       // Memory control
    wire RegWrite;                // Register write enable
    wire MemOrIOtoReg;            // Select mem/IO->reg
    wire IOReadUnsigned, IOReadSigned, IOWrite; // IO control
    wire LEDCtrl, SwitchCtrl, TubeCtrl; // Peripheral control
    
    // Branch and jump signals
    wire jump, jalr;              // Jump controls
    wire beq, bne, blt, bltu, bge, bgeu; // Branch controls
    wire [31:0] ra;               // Return address
    
    // IO signals
    wire [15:0] io_rdata;         // Data from IO devices
    
    // Map reset signal
    assign rst = fpga_rst;
    
    // Clock generation
    Clock Clock(
        .clk_in1(fpga_clk),
        .rst(rst),
        .clk_out1(cpu_clk),
        .clk_out2(clk_div_2s)
    );

    // Instruction fetch and PC update
    IFetch IFetch(
        .clk(cpu_clk),
        .rst(rst),
        .imm32(imm32),
        .jump(jump),
        .jalr(jalr),
        .beq(beq),
        .bne(bne),
        .bge(bge),
        .blt(blt),
        .bgeu(bgeu),
        .bltu(bltu),
        .zero(zero),
        .negative(negative),
        .unsigned_less(unsigned_less),
        .ALUResult(ALU_result),
        .ra(ra),
        .inst(inst)
    );

    // Instruction decode and register file
    Decoder Decoder(
        .clk(cpu_clk),
        .rst(rst),
        .ALU_result(ALU_result),
        .MemOrIOtoReg(MemOrIOtoReg),
        .regWrite(RegWrite),
        .inst(inst),
        .ra(ra),
        .jump(jump),
        .IOData(mem_data),
        .IOReadSigned(IOReadSigned),
        .IOReadUnsigned(IOReadUnsigned),
        .rs1Data(read_data_1),
        .rs2Data(read_data_2),
        .imm32(imm32)
    );
    
    // Control signal generation
    Controller Controller(
        .inst(inst),
        .ALU_result_high(ALU_result[31:10]),
        .Jump(jump),
        .jalr(jalr),
        .beq(beq),
        .blt(blt),
        .bge(bge),
        .bltu(bltu),
        .bgeu(bgeu),
        .MemRead(MemRead),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .MemOrIOtoReg(MemOrIOtoReg),
        .IOReadUnsigned(IOReadUnsigned),
        .IOReadSigned(IOReadSigned),
        .IOWrite(IOWrite),
        .bne(bne)
    );
    
    // Data memory access
    DataMem DataMem(
        .clk(cpu_clk),
        .mem_write(MemWrite),
        .mem_read(MemRead),
        .addr(addr_out),
        .din(read_data_2),
        .dout(ram_dat_o)
    );

    // ALU operations
    ALU ALU(
        .ReadData1(read_data_1),
        .ReadData2(read_data_2),
        .imm32(imm32),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .funct3(inst[14:12]),
        .funct7(inst[31:25]),
        .ALUResult(ALU_result),
        .zero(zero),
        .negative(negative),
        .unsigned_less(unsigned_less)
    );
    
    // Memory/IO interface
    MemOrIO MemOrIO(
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

    // IO peripherals
    Switch Switch(
        .clk(fpga_clk),
        .rst(rst),
        .IOReadUnsigned(IOReadUnsigned),
        .IOReadSigned(IOReadSigned),
        .SwitchCtrl(SwitchCtrl),
        .switch(switch),
        .button(button),
        .switchaddr(addr_out[7:0]),
        .switchrdata(io_rdata)
    );
    
    Led Led(
        .clk(cpu_clk),
        .rst(rst),
        .IOWrite(IOWrite),
        .LEDCtrl(LEDCtrl),
        .ledaddr(addr_out[7:0]),
        .ledwdata(write_data[15:0]),
        .led(led)
    );
    
    Tube Tube(
        .clk(cpu_clk),
        .fpga_clk(fpga_clk),
        .rst(rst),
        .clk_div_2s(clk_div_2s),
        .button(button[3]),
        .button2(button[2]),
        .IOWrite(IOWrite),
        .TubeCtrl(TubeCtrl),
        .tubeaddr(addr_out[7:0]),
        .tubewdata(write_data[15:0]),
        .tubewdata32(write_data_32),
        .testcase(write_data[15:0]),
        .sel(tube_sel),
        .tube0(tube0),
        .tube1(tube1)
    );

endmodule