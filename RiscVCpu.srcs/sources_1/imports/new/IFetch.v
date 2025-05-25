`timescale 1ns / 1ps

module IFetch(
    input clk,
    input rst,
    input [31:0] imm32,
    input [31:0] rs1Data,      
    input jump,
    input jalr,         
    input beq, 
    input bne,         
    input blt,           
    input bltu,        
    input bge,          
    input bgeu,          
    input zero,
    input negative,
    input unsignedLess,
    input [31:0] aluResult,    // Use ALU result for JALR
    output reg [31:0] ra,
    output wire [31:0] inst,
    output wire [31:0] pc_out
);

    reg [31:0] pc = 32'h00000000;
    reg [31:0] npc;
    wire [13:0] addra;

    assign pc_out = pc;

    prgrom urom(
        .clka(clk),
        .addra(addra),
        .douta(inst)
    );

    assign addra = pc[15:2];

    // Next PC calculation logic - FIXED JALR
    always @(*) begin
        if ((beq && zero) ||
            (bne && ~zero) ||
            (blt && negative) ||
            (bge && ~negative) ||
            (bltu && unsignedLess) ||
            (bgeu && ~unsignedLess)) begin
            npc = pc + imm32;
        end 
        else if (jump) begin                     
            npc = pc + imm32;
        end 
        else if (jalr) begin
            // JALR: Use ALU result (rs1 + imm) with LSB cleared
            npc = {aluResult[31:1], 1'b0};
        end 
        else begin
            npc = pc + 4;
        end
    end

    // Return address calculation
    always @(posedge clk) begin
        ra <= pc + 4;  // Added non-blocking assignment
    end

    // PC update
    always @(negedge clk or negedge rst) begin
        if (~rst) begin
            pc <= 32'h00000000;
        end 
        else begin
            pc <= npc;
        end
    end

endmodule