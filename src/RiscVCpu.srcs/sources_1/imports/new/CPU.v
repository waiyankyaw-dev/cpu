module CPU(
    input fpgaRst,
    input fpgaClk,
    input [11:0] switch,
    input [3:0] button,
    
    output [15:0] led,
    output [7:0] tubeSel,
    output [7:0] tube0,
    output [7:0] tube1
);

    // Internal signal declarations
    wire cpuClk;
    wire rst;
    wire [31:0] inst;
    wire [31:0] imm32;
    wire [31:0] pc;              // Added PC signal
    
    // ALU and branch control signals
    wire zero, negative, unsignedLess;
    wire [31:0] aluResult;
    wire [1:0] aluOp;
    wire aluSrc;
    
    // Register and memory signals
    wire [31:0] readData1;
    wire [31:0] readData2;
    wire [31:0] writeData;
    wire [31:0] writeData32;
    wire [31:0] addrOut;
    wire [31:0] ramDataOut;
    wire [31:0] memData;
    
    // Control signals
    wire memRead, memWrite;
    wire regWrite;
    wire memOrIOtoReg;
    wire ioReadUnsigned, ioReadSigned, ioWrite;
    wire ledCtrl, switchCtrl, tubeCtrl;
    
    // Branch and jump signals
    wire jump, jalr;
    wire beq, bne, blt, bltu, bge, bgeu;
    wire [31:0] ra;
    
    // IO signals
    wire [15:0] ioRdata;
    
    assign rst = fpgaRst;
    
    Clock clock(
        .clkIn1(fpgaClk),
        .rst(rst),
        .clkOut1(cpuClk)
    );

    // Fixed IFetch with PC output and rs1Data input
    IFetch iFetch(
        .clk(cpuClk),
        .rst(rst),
        .imm32(imm32),
        .rs1Data(readData1),       // Added rs1Data for JALR
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
        .inst(inst),
        .pc_out(pc)                // Added PC output
    );

    // Fixed Decoder with PC input and JALR signal
    Decoder decoder(
        .clk(cpuClk),
        .rst(rst),
        .aluResult(aluResult),
        .pc(pc),                   // Added PC input
        .memOrIOtoReg(memOrIOtoReg),
        .regWrite(regWrite),
        .inst(inst),
        .ra(ra),
        .jump(jump),
        .jalr(jalr),               // Added JALR signal
        .ioData(memData),
        .ioReadSigned(ioReadSigned),
        .ioReadUnsigned(ioReadUnsigned),
        .rs1Data(readData1),
        .rs2Data(readData2),
        .imm32(imm32)
    );
    
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
    
    DataMem dataMem(
        .clk(cpuClk),
        .memWrite(memWrite),
        .memRead(memRead),
        .addr(addrOut),
        .din(readData2),
        .dout(ramDataOut)
    );

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

    Switch switchModule(
        .clk(fpgaClk),
        .rst(rst),
        .ioReadUnsigned(ioReadUnsigned),
        .ioReadSigned(ioReadSigned),
        .switchCtrl(switchCtrl),
        .switch(switch),
        .button(button),
        .switchAddr(addrOut[7:0]),
        .switchReadData(ioRdata)
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