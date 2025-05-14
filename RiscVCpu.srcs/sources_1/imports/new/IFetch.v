`timescale 1ns / 1ps

module IFetch(
    input clk,
    input rst,
    input [31:0] imm32,
    input jump,          // jal
    input jalr,          // jalr
    input beq,           // Branch if equal
    input bne,           // Branch if not equal
    input blt,           // Branch if less than
    input bltu,          // Branch if less than unsigned
    input bge,           // Branch if greater or equal
    input bgeu,          // Branch if greater or equal unsigned
    input zero,          // Zero flag from ALU
    input negative,      // Negative flag from ALU
    input unsignedLess,  // Unsigned less flag from ALU
    input [31:0] aluResult,
    output reg [31:0] ra,
    output wire [31:0] inst
);

    reg [31:0] pc = 32'h00000000;
    reg [31:0] npc;
    wire [13:0] addra;

    // Instantiate program ROM IP core
    prgrom urom(
        .clka(clk),
        .addra(addra),
        .douta(inst)
    );

    // Word-aligned address for instruction fetch
    assign addra = pc[15:2];

    // Next PC calculation logic
    always @(*) begin
        if ((beq && zero) ||                     // Branch if equal and zero flag set
            (bne && ~zero) ||                    // Branch if not equal and zero flag clear
            (blt && negative) ||                 // Branch if less than and result negative
            (bge && ~negative) ||                // Branch if greater/equal and result non-negative
            (bltu && unsignedLess) ||            // Branch if less than unsigned
            (bgeu && ~unsignedLess)) begin       // Branch if greater/equal unsigned
            npc = pc + imm32;                    // Branch target address
        end 
        else if (jump) begin                     // JAL instruction
            npc = pc + imm32;                    // Jump target address
        end 
        else if (jalr) begin                     // JALR instruction
            npc = aluResult;                     // Jump to address in register
        end 
        else begin
            npc = pc + 4;                        // Sequential execution
        end
    end

    // Return address calculation
    always @(posedge clk) begin
        ra = pc + 4;                             // Store return address
    end

    // PC update
    always @(negedge clk or negedge rst) begin
        if (~rst) begin
            pc <= 32'h00000000;                  // Reset PC to initial value
        end 
        else begin
            pc <= npc;                           // Update PC with next address
        end
    end

endmodule