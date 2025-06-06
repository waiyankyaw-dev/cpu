`timescale 1ns / 1ps

module ALU (
    input [31:0] readData1, 
    input [31:0] readData2, 
    input [31:0] imm32, 
    input aluSrc,
    input [1:0] aluOp, 
    input [2:0] funct3, 
    input [6:0] funct7, 
    output reg [31:0] aluResult, 
    output wire zero,
    output wire negative,   
    output wire unsignedLess // for unsigned comparisons
);
    integer i;
    wire [31:0] operand2;
    reg [4:0] aluControl; // 5 bits to handle more operations
 
    assign operand2 = (aluSrc) ? imm32 : readData2;
    assign zero = (aluResult == 0);
    assign negative = aluResult[31];
    assign unsignedLess = (readData1 < operand2); // =1 if bltu, 0 if bgeu

    // ALU operation codes
    localparam ALU_AND     = 5'b00000;
    localparam ALU_OR      = 5'b00001;
    localparam ALU_ADD     = 5'b00010;
    localparam ALU_SUB     = 5'b00110;
    localparam ALU_SLL     = 5'b00111;
    localparam ALU_SRA     = 5'b01000;
    localparam ALU_SRL     = 5'b01001;
    localparam ALU_SLT     = 5'b01010;
    localparam ALU_SLTU    = 5'b01011;
    localparam ALU_XOR     = 5'b10000;

    //decode
    always @* begin
        case(aluOp)
            2'b00: aluControl = ALU_ADD;  // load/store (use add)
            2'b01: aluControl = ALU_SUB;  // branch (both signed and unsigned use sub)
            
            2'b10: begin // R-type
                case({funct7[5], funct3})
                    4'b0000: aluControl = ALU_ADD;  // add
                    4'b1000: aluControl = ALU_SUB;  // sub
                    4'b0111: aluControl = ALU_AND;  // and
                    4'b0110: aluControl = ALU_OR;   // or
                    4'b0010: aluControl = ALU_SLT;  // slt
                    4'b0011: aluControl = ALU_SLTU; // sltu
                    4'b0001: aluControl = ALU_SLL;  // sll
                    4'b1101: aluControl = ALU_SRA;  // sra
                    4'b0101: aluControl = ALU_SRL;  // srl
                    4'b0100: aluControl = ALU_XOR;  // xor
                    default: aluControl = 5'b00000;
                endcase
            end
            
            2'b11: begin // I-type
                case(funct3)
                    3'b000: aluControl = ALU_ADD;  // addi
                    3'b010: aluControl = ALU_SLT;  // slti
                    3'b011: aluControl = ALU_SLTU; // sltiu
                    3'b100: aluControl = ALU_XOR;  // xoric
                    3'b110: aluControl = ALU_OR;   // ori
                    3'b111: aluControl = ALU_AND;  // andi
                    3'b001: aluControl = ALU_SLL;  // slli
                    3'b101: aluControl = (funct7[5]) ? ALU_SRA : ALU_SRL; // srai, srli
                    default: aluControl = 5'b00000;
                endcase
            end
            default: aluControl = 5'b00000;
        endcase
    end

    // ALU operations
    always @* begin
        case (aluControl)
            ALU_AND:    aluResult = readData1 & operand2;      // and
            ALU_OR:     aluResult = readData1 | operand2;      // or
            ALU_ADD:    aluResult = readData1 + operand2;      // add
            ALU_SUB:    aluResult = readData1 - operand2;      // sub
            ALU_SLL:    aluResult = readData1 << operand2[4:0]; // sll
            ALU_SRA:    aluResult = $signed(readData1) >>> operand2[4:0]; // sra
            ALU_SRL:    aluResult = readData1 >> operand2[4:0]; // srl
            ALU_SLT:    aluResult = {31'b0, $signed(readData1) < $signed(operand2)}; // slt
            ALU_SLTU:   aluResult = {31'b0, readData1 < operand2}; // sltu 
            ALU_XOR:    aluResult = readData1 ^ operand2;      // xor
            default:    aluResult = 32'b0;
        endcase
    end
endmodule