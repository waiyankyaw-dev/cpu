`timescale 1ns / 1ps

module CPU(
    input fpgaRst,               // FPGA reset button
    input fpgaClk,               // FPGA clock
    input [11:0] switch,         // 11 DIP switches
    input [3:0] button,          // 4 push buttons
    
    output [15:0] led,           // 16 LEDs
    output [7:0] tubeSel,        // 7-segment display digit select
    output [7:0] tube0,          // 7-segment display upper segments
    output [7:0] tube1           // 7-segment display lower segments
);

    // Internal signal declarations
    wire cpuClk;                 // CPU clock
    wire rst;                    // Reset signal
    
    // Instruction fetch signals
    wire [31:0] inst;            // Current instruction
    wire [31:0] imm32;           // Immediate value
    
    // ALU and branch control signals
    wire zero, negative, unsignedLess;
    wire [31:0] aluResult;       // ALU result
    wire [1:0] aluOp;            // ALU operation select
    wire aluSrc;                 // ALU source select (reg/imm)
    
    // Register and memory signals
    wire [31:0] readData1;       // Register source 1
    wire [31:0] readData2;       // Register source 2
    wire [31:0] writeData;       // Data for memory/IO write
    wire [31:0] writeData32;     // Full 32-bit data for IO
    wire [31:0] addrOut;         // Memory/IO address
    wire [31:0] ramDataOut;      // Data from memory
    wire [31:0] memData;         // Data to register file
    
    // Control signals
    wire memRead, memWrite;      // Memory control
    wire regWrite;               // Register write enable
    wire memOrIOtoReg;           // Select mem/IO->reg
    wire ioReadUnsigned, ioReadSigned, ioWrite; // IO control
    wire ledCtrl, switchCtrl, tubeCtrl; // Peripheral control
    
    // Branch and jump signals
    wire jump, jalr;             // Jump controls
    wire beq, bne, blt, bltu, bge, bgeu; // Branch controls
    wire [31:0] ra;              // Return address
    
    // IO signals
    wire [15:0] ioRdata;         // Data from IO devices
    
    // Map reset signal
    assign rst = fpgaRst;
    
    // Clock generation
    Clock clock(
        .clkIn1(fpgaClk),
        .rst(rst),
        .clkOut1(cpuClk)
    );

    // Instruction fetch and PC update
    IFetch iFetch(
        .clk(cpuClk),
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
        .unsignedLess(unsignedLess),
        .aluResult(aluResult),
        .ra(ra),
        .inst(inst)
    );

    // Instruction decode and register file
    Decoder decoder(
        .clk(cpuClk),
        .rst(rst),
        .aluResult(aluResult),
        .memOrIOtoReg(memOrIOtoReg),
        .regWrite(regWrite),
        .inst(inst),
        .ra(ra),
        .jump(jump),
        .ioData(memData),
        .ioReadSigned(ioReadSigned),
        .ioReadUnsigned(ioReadUnsigned),
        .rs1Data(readData1),
        .rs2Data(readData2),
        .imm32(imm32)
    );
    
    // Control signal generation
    Controller controller(
        .inst(inst),
        .aluResultHigh(aluResult[31:10]),
        .jump(jump),
        .jalr(jalr),
        .beq(beq),
        .blt(blt),
        .bge(bge),
        .bltu(bltu),
        .bgeu(bgeu),
        .memRead(memRead),
        .aluOp(aluOp),
        .memWrite(memWrite),
        .aluSrc(aluSrc),
        .regWrite(regWrite),
        .memOrIOtoReg(memOrIOtoReg),
        .ioReadUnsigned(ioReadUnsigned),
        .ioReadSigned(ioReadSigned),
        .ioWrite(ioWrite),
        .bne(bne)
    );
    
    // Data memory access
    DataMem dataMem(
        .clk(cpuClk),
        .memWrite(memWrite),
        .memRead(memRead),
        .addr(addrOut),
        .din(readData2),
        .dout(ramDataOut)
    );

    // ALU operations
    ALU alu(
        .readData1(readData1),
        .readData2(readData2),
        .imm32(imm32),
        .aluSrc(aluSrc),
        .aluOp(aluOp),
        .funct3(inst[14:12]),
        .funct7(inst[31:25]),
        .aluResult(aluResult),
        .zero(zero),
        .negative(negative),
        .unsignedLess(unsignedLess)
    );
    
    // Memory/IO interface
    MemOrIO memOrIO(
        .mRead(memRead),
        .mWrite(memWrite),
        .ioReadUnsigned(ioReadUnsigned),
        .ioReadSigned(ioReadSigned),
        .ioWrite(ioWrite),
        .addrIn(aluResult),
        .addrOut(addrOut),
        .mRdata(ramDataOut),
        .ioRdata(ioRdata),
        .rWdata(memData),
        .rRdata(readData2),
        .writeData(writeData),
        .writeData32(writeData32),
        .ledCtrl(ledCtrl),
        .switchCtrl(switchCtrl),
        .tubeCtrl(tubeCtrl)
    );

    // IO peripherals
    Switch switchModule(
        .clk(fpgaClk),
        .rst(rst),
        .ioReadUnsigned(ioReadUnsigned),
        .ioReadSigned(ioReadSigned),
        .switchCtrl(switchCtrl),
        .switch(switch),
        .button(button),
        .switchAddr(addrOut[7:0]),
        .switchRdata(ioRdata)
    );
    
    Led ledModule(
        .clk(cpuClk),
        .rst(rst),
        .ioWrite(ioWrite),
        .ledCtrl(ledCtrl),
        .ledAddr(addrOut[7:0]),
        .ledWdata(writeData[15:0]),
        .led(led)
    );
    
    Tube tubeModule(
        .clk(cpuClk),
        .fpgaClk(fpgaClk),
        .rst(rst),
        .ioWrite(ioWrite),
        .tubeCtrl(tubeCtrl),
        .tubeAddr(addrOut[7:0]),
        .tubeWdata(writeData[15:0]),
        .tubeWdata32(writeData32),
        .sel(tubeSel),
        .tube0(tube0),
        .tube1(tube1)
    );

endmodule