`timescale 1ns / 1ps

module Controller (
    input [31:0] inst,
    input [21:0] aluResultHigh,
    output wire jump,                
    output wire jalr,               
    output wire beq,                   
    output wire bne,                   
    output wire blt,                     
    output wire bltu,                   
    output wire bge,                    
    output wire bgeu,                    
    output wire memRead,
    output reg [1:0] aluOp,
    output wire memWrite,
    output reg aluSrc,
    output wire regWrite,
    output wire memOrIOtoReg,
    output wire ioReadUnsigned,
    output wire ioReadSigned,
    output wire ioWrite
);

    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];

    // Instruction type identification
    wire rFormat     = (opcode == 7'b0110011);
    wire iFormatArith = (opcode == 7'b0010011);
    wire lw          = (opcode == 7'b0000011 && funct3 == 3'b010);
    wire lb          = (opcode == 7'b0000011 && funct3 == 3'b000);
    wire lbu         = (opcode == 7'b0000011 && funct3 == 3'b100);
    wire sw          = (opcode == 7'b0100011 && funct3 == 3'b010);
    wire lui         = (opcode == 7'b0110111);
    wire auipc       = (opcode == 7'b0010111);  // Added AUIPC
    assign beq       = (opcode == 7'b1100011 && funct3 == 3'b000);
    assign bne       = (opcode == 7'b1100011 && funct3 == 3'b001);
    assign blt       = (opcode == 7'b1100011 && funct3 == 3'b100);
    assign bltu      = (opcode == 7'b1100011 && funct3 == 3'b110);
    assign jump      = (opcode == 7'b1101111);
    assign jalr      = (opcode == 7'b1100111 && funct3 == 3'b000);
    assign bge       = (opcode == 7'b1100011 && funct3 == 3'b101);
    assign bgeu      = (opcode == 7'b1100011 && funct3 == 3'b111);

    localparam IO_ADDRESS_HIGH = 22'h3FFFFF;

    // Register write control - Added AUIPC
    assign regWrite = rFormat || iFormatArith || lw || lb || lbu || 
                     lui || auipc || jump || jalr;

    // Memory and I/O control
    assign memWrite      = sw && (aluResultHigh != IO_ADDRESS_HIGH);
    assign memRead       = lw && (aluResultHigh != IO_ADDRESS_HIGH);
    assign ioWrite       = sw && (aluResultHigh == IO_ADDRESS_HIGH);
    assign ioReadSigned  = (lw || lb) && (aluResultHigh == IO_ADDRESS_HIGH);
    assign ioReadUnsigned = lbu && (aluResultHigh == IO_ADDRESS_HIGH);
    assign memOrIOtoReg  = memRead || ioReadSigned || ioReadUnsigned;

    // ALU control - Added AUIPC case
    always @(*) begin
        case (opcode)
            7'b0000011: aluOp = 2'b00; // Load: add for address calculation
            7'b0100011: aluOp = 2'b00; // Store: add for address calculation
            7'b1100011: aluOp = 2'b01; // Branch: subtract/compare
            7'b0110011: aluOp = 2'b10; // R-type
            7'b0010011: aluOp = 2'b11; // I-type arithmetic
            7'b0110111: aluOp = 2'b00; // LUI: pass immediate
            7'b0010111: aluOp = 2'b00; // AUIPC: add PC + immediate
            7'b1101111: aluOp = 2'b00; // JAL: add PC + immediate
            7'b1100111: aluOp = 2'b00; // JALR: add rs1 + immediate
            default:    aluOp = 2'b00;
        endcase
    end

    // ALU source selection - Added AUIPC case
    always @(*) begin
        case (opcode)
            7'b0000011: aluSrc = 1'b1; // Load: immediate
            7'b0100011: aluSrc = 1'b1; // Store: immediate
            7'b0010011: aluSrc = 1'b1; // I-type arithmetic: immediate
            7'b0110111: aluSrc = 1'b1; // LUI: immediate
            7'b0010111: aluSrc = 1'b1; // AUIPC: immediate
            7'b1101111: aluSrc = 1'b1; // JAL: immediate
            7'b1100111: aluSrc = 1'b1; // JALR: immediate
            default:    aluSrc = 1'b0; // R-type, branch: rs2
        endcase
    end

endmodule