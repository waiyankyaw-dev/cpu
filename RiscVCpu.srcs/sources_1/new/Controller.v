`timescale 1ns / 1ps

module Controller (
    input [31:0] inst,                    // 32-bit instruction
    input [21:0] ALU_result_high,         // Upper 22 bits of ALU result for I/O detection
    output wire Jump,                     // jal instruction
    output wire jalr,                     // jalr instruction
    output wire beq,                      // beq instruction
    output wire bne,                      // bne instruction
    output wire blt,                      // blt instruction
    output wire bltu,                     // bltu instruction
    output wire MemRead,                  // Enable memory read
    output reg [1:0] ALUOp,               // ALU operation selector
    output wire MemWrite,                 // Enable memory write
    output reg ALUSrc,                    // ALU second operand (0: rs2, 1: imm)
    output wire RegWrite,                 // Enable register write
    output wire MemOrIOtoReg,             // Select memory/I/O data for register write
    output wire IOReadUnsigned,           // Enable unsigned I/O read (lbu)
    output wire IOReadSigned,             // Enable signed I/O read (lb, lw)
    output wire IOWrite                   // Enable I/O write (sw)
);

    // Opcode and funct3 extraction
    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];

    // Instruction type identification
    wire RFormat        = (opcode == 7'b0110011);           // R-type (add, slt, sltu, xor, sll, srl)
    wire IFormat_arith  = (opcode == 7'b0010011);           // I-type arithmetic (addi, slli, srli, xori)
    wire lw             = (opcode == 7'b0000011 && funct3 == 3'b010); // Load word
    wire lb             = (opcode == 7'b0000011 && funct3 == 3'b000); // Load byte
    wire lbu            = (opcode == 7'b0000011 && funct3 == 3'b100); // Load byte unsigned
    wire sw             = (opcode == 7'b0100011 && funct3 == 3'b010); // Store word
    wire lui            = (opcode == 7'b0110111);           // Load upper immediate
    assign beq            = (opcode == 7'b1100011 && funct3 == 3'b000); // Branch equal
    assign bne            = (opcode == 7'b1100011 && funct3 == 3'b001); // Branch not equal
    assign blt            = (opcode == 7'b1100011 && funct3 == 3'b100); // Branch less than
    assign bltu           = (opcode == 7'b1100011 && funct3 == 3'b110); // Branch less than unsigned
    assign Jump           = (opcode == 7'b1101111);           // jal
    assign jalr           = (opcode == 7'b1100111 && funct3 == 3'b000); // jalr

    // I/O address detection
    localparam IO_ADDRESS_HIGH = 22'h3FFFFF; // Upper bits for I/O addresses (0xfffffcXX)

    // Register write control
    assign RegWrite = RFormat || IFormat_arith || lw || lb || lbu || lui || Jump || jalr;

    // Memory and I/O control
    assign MemWrite      = sw && (ALU_result_high != IO_ADDRESS_HIGH);
    assign MemRead       = lw && (ALU_result_high != IO_ADDRESS_HIGH);
    assign IOWrite       = sw && (ALU_result_high == IO_ADDRESS_HIGH);
    assign IOReadSigned  = (lw || lb) && (ALU_result_high == IO_ADDRESS_HIGH);
    assign IOReadUnsigned = lbu && (ALU_result_high == IO_ADDRESS_HIGH);
    assign MemOrIOtoReg  = MemRead || IOReadSigned || IOReadUnsigned;

    // ALU control
    always @(*) begin
        case (opcode)
            7'b0000011: ALUOp = 2'b00; // Load (lw, lb, lbu): add for address calculation
            7'b0100011: ALUOp = 2'b00; // Store (sw): add for address calculation
            7'b1100011: ALUOp = 2'b01; // Branch (beq, bne, blt, bltu): subtract/compare
            7'b0110011: ALUOp = 2'b10; // R-type (add, slt, sltu, xor, sll, srl)
            7'b0010011: ALUOp = 2'b11; // I-type arithmetic (addi, slli, srli, xori)
            7'b0110111: ALUOp = 2'b00; // lui: no ALU operation (pass immediate)
            7'b1101111: ALUOp = 2'b00; // jal: no ALU operation
            7'b1100111: ALUOp = 2'b00; // jalr: add for address calculation
            default:    ALUOp = 2'b00; // Default: no ALU operation
        endcase
    end

    // ALU source selection
    always @(*) begin
        case (opcode)
            7'b0000011: ALUSrc = 1'b1; // Load (lw, lb, lbu): immediate
            7'b0100011: ALUSrc = 1'b1; // Store (sw): immediate
            7'b0010011: ALUSrc = 1'b1; // I-type arithmetic (addi, slli, srli, xori): immediate
            7'b0110111: ALUSrc = 1'b1; // lui: immediate
            7'b1101111: ALUSrc = 1'b1; // jal: immediate
            7'b1100111: ALUSrc = 1'b1; // jalr: immediate
            default:    ALUSrc = 1'b0; // R-type, branch: rs2
        endcase
    end

endmodule