`timescale 1ns / 1ps
module ALU (
    input [31:0] ReadData1, ReadData2, imm32, 
    input ALUSrc,
    input [1:0] ALUOp, 
    input [2:0] funct3, 
    input [6:0] funct7, 
    output reg [31:0] ALUResult, 
    output wire zero,
    output wire negative,   
    output wire unsigned_less // for unsigned comparisons
    );
    integer i;
    wire [31:0] operand2;
    reg [4:0] ALUControl; // 5 bits to handle more operations
 
    assign operand2 = (ALUSrc) ? imm32 : ReadData2;
    assign zero = (ALUResult == 0);

    assign negative = ALUResult[31];
    assign unsigned_less = (ReadData1 < operand2); // =1 if bltu , 0 if bgeu

    localparam ALU_AND    = 5'b00000;
    localparam ALU_OR     = 5'b00001;
    localparam ALU_ADD    = 5'b00010;
    localparam ALU_SUB    = 5'b00110;
    localparam ALU_SLL    = 5'b00111;
    localparam ALU_SRA    = 5'b01000;
    localparam ALU_SRL    = 5'b01001;
    localparam ALU_SLT    = 5'b01010;
    localparam ALU_SLTU   = 5'b01011;
    // localparam ALU_BGEU   = 5'b01100;
    localparam ALU_XOR    = 5'b10000;
    localparam ALU_BITREV = 5'b10001;

    //decode
    always @* begin
        case(ALUOp)
            2'b00: ALUControl = ALU_ADD;  // load/store (use add)
            2'b01: ALUControl = ALU_SUB; //branch (both signed and unsigned use sub, and we diffrentiate it by signed bit)
            
            2'b10: begin // R-type
                case({funct7[5], funct3})
                    4'b0000: ALUControl = ALU_ADD;  // add
                    4'b1000: ALUControl = ALU_SUB;  // sub
                    4'b0111: ALUControl = ALU_AND;  // and
                    4'b0110: ALUControl = ALU_OR;   // or
                    4'b0010: ALUControl = ALU_SLT;  // slt
                    4'b0011: ALUControl = ALU_SLTU; // sltu
                    4'b0001: ALUControl = ALU_SLL;  // sll
                    4'b1101: ALUControl = ALU_SRA;  // sra
                    4'b0101: ALUControl = ALU_SRL;  // srl
                    4'b0100: ALUControl = ALU_XOR;  // xor
                    4'b0110: ALUControl = ALU_BITREV; // bit reverse
                    default: ALUControl = 5'b00000;
                endcase
            end
            2'b11: begin // I-type
                case(funct3)
                    3'b000: ALUControl = ALU_ADD;  // addi
                    3'b010: ALUControl = ALU_SLT;  // slti
                    3'b011: ALUControl = ALU_SLTU; // sltiu
                    3'b100: ALUControl = ALU_XOR;  // xori
                    3'b110: ALUControl = ALU_OR;   // ori
                    3'b111: ALUControl = ALU_AND;  // andi
                    3'b001: ALUControl = ALU_SLL;  // slli
                    3'b101: ALUControl = (funct7[5]) ? ALU_SRA : ALU_SRL; // srai, srli
                    default: ALUControl = 5'b00000;
                endcase
            end
            default: ALUControl = 5'b00000;
        endcase
    end


    always @* begin
        case (ALUControl)
            ALU_AND:ALUResult = ReadData1 & operand2;    //and
            ALU_OR:   ALUResult = ReadData1 | operand2;    //or
            ALU_ADD: ALUResult = ReadData1 + operand2;    //add
            ALU_SUB:ALUResult = ReadData1 - operand2;    // sub
            ALU_SLL:ALUResult = ReadData1 << operand2[4:0]; // sll
            ALU_SRA:ALUResult = $signed(ReadData1) >>> operand2[4:0]; // sra
            ALU_SRL:ALUResult = ReadData1 >> operand2[4:0]; // srl
            ALU_SLT:ALUResult = {31'b0, $signed(ReadData1) < $signed(operand2)}; // slt
            ALU_SLTU:ALUResult = {31'b0, ReadData1 < operand2}; //sltu 
            // ALU_BGEU:ALUResult = ReadData1 - operand2;    // sub 
            ALU_XOR: ALUResult = ReadData1 ^ operand2;    //xor
            ALU_BITREV: begin //bit reverse (8-bit)
             
                for (i = 0; i < 8; i = i + 1)
                    ALUResult[i] = ReadData1[7-i];
                ALUResult[31:8] = 0;
            end
            default: ALUResult = 32'b0;
        endcase
    end
endmodule