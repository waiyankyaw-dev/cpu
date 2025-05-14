`timescale 1ns / 1ps

module Controller (
    input [31:0] inst,                   // 32-bit instruction
    input [21:0] aluResultHigh,          // Upper 22 bits of ALU result for I/O detection
    output wire jump,                    // jal instruction
    output wire jalr,                    // jalr instruction
    output wire beq,                     // beq instruction
    output wire bne,                     // bne instruction
    output wire blt,                     // blt instruction
    output wire bltu,                    // bltu instruction
    output wire bge,                     // bge instruction
    output wire bgeu,                    // bgeu instruction
    output wire memRead,                 // Enable memory read
    output reg [1:0] aluOp,              // ALU operation selector
    output wire memWrite,                // Enable memory write
    output reg aluSrc,                   // ALU second operand (0: rs2, 1: imm)
    output wire regWrite,                // Enable register write
    output wire memOrIOtoReg,            // Select memory/I/O data for register write
    output wire ioReadUnsigned,          // Enable unsigned I/O read (lbu)
    output wire ioReadSigned,            // Enable signed I/O read (lb, lw)
    output wire ioWrite                  // Enable I/O write (sw)
);

    // Opcode and funct3 extraction
    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];

    // Instruction type identification
    wire rFormat        = (opcode == 7'b0110011);           // R-type (add, slt, sltu, xor, sll, srl)
    wire iFormatArith   = (opcode == 7'b0010011);           // I-type arithmetic (addi, slli, srli, xori)
    wire lw             = (opcode == 7'b0000011 && funct3 == 3'b010); // Load word
    wire lb             = (opcode == 7'b0000011 && funct3 == 3'b000); // Load byte
    wire lbu            = (opcode == 7'b0000011 && funct3 == 3'b100); // Load byte unsigned
    wire sw             = (opcode == 7'b0100011 && funct3 == 3'b010); // Store word
    wire lui            = (opcode == 7'b0110111);           // Load upper immediate
    assign beq          = (opcode == 7'b1100011 && funct3 == 3'b000); // Branch equal
    assign bne          = (opcode == 7'b1100011 && funct3 == 3'b001); // Branch not equal
    assign blt          = (opcode == 7'b1100011 && funct3 == 3'b100); // Branch less than
    assign bltu         = (opcode == 7'b1100011 && funct3 == 3'b110); // Branch less than unsigned
    assign jump         = (opcode == 7'b1101111);           // jal
    assign jalr         = (opcode == 7'b1100111 && funct3 == 3'b000); // jalr
    assign bge          = (opcode == 7'b1100011 && funct3 == 3'b101); // Branch greater or equal
    assign bgeu         = (opcode == 7'b1100011 && funct3 == 3'b111); // Branch greater or equal unsigned

    // I/O address detection
    localparam IO_ADDRESS_HIGH = 22'h3FFFFF; // Upper bits for I/O addresses (0xfffffcXX)

    // Register write control
    assign regWrite = rFormat || iFormatArith || lw || lb || lbu || lui || jump || jalr;

    // Memory and I/O control
    assign memWrite      = sw && (aluResultHigh != IO_ADDRESS_HIGH);
    assign memRead       = lw && (aluResultHigh != IO_ADDRESS_HIGH);
    assign ioWrite       = sw && (aluResultHigh == IO_ADDRESS_HIGH);
    assign ioReadSigned  = (lw || lb) && (aluResultHigh == IO_ADDRESS_HIGH);
    assign ioReadUnsigned = lbu && (aluResultHigh == IO_ADDRESS_HIGH);
    assign memOrIOtoReg  = memRead || ioReadSigned || ioReadUnsigned;

    // ALU control
    always @(*) begin
        case (opcode)
            7'b0000011: aluOp = 2'b00; // Load (lw, lb, lbu): add for address calculation
            7'b0100011: aluOp = 2'b00; // Store (sw): add for address calculation
            7'b1100011: aluOp = 2'b01; // Branch (beq, bne, blt, bltu): subtract/compare
            7'b0110011: aluOp = 2'b10; // R-type (add, slt, sltu, xor, sll, srl)
            7'b0010011: aluOp = 2'b11; // I-type arithmetic (addi, slli, srli, xori)
            7'b0110111: aluOp = 2'b00; // lui: no ALU operation (pass immediate)
            7'b1101111: aluOp = 2'b00; // jal: no ALU operation
            7'b1100111: aluOp = 2'b00; // jalr: add for address calculation
            default:    aluOp = 2'b00; // Default: no ALU operation
        endcase
    end

    // ALU source selection
    always @(*) begin
        case (opcode)
            7'b0000011: aluSrc = 1'b1; // Load (lw, lb, lbu): immediate
            7'b0100011: aluSrc = 1'b1; // Store (sw): immediate
            7'b0010011: aluSrc = 1'b1; // I-type arithmetic (addi, slli, srli, xori): immediate
            7'b0110111: aluSrc = 1'b1; // lui: immediate
            7'b1101111: aluSrc = 1'b1; // jal: immediate
            7'b1100111: aluSrc = 1'b1; // jalr: immediate
            default:    aluSrc = 1'b0; // R-type, branch: rs2
        endcase
    end

endmodule