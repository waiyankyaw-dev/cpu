`timescale 1ns / 1ps

module CPU(
    // input fpga_rst, 
    // input fpga_clk,
    // add swtich 16bits
    // add button ? bits
    // add led 16 bits
    // tube selection 8 bits
    // tube0 8 bits
    // tube1 8 bits
);
    wire rst; 
    wire zero, MemRead, MemWrite, MemToReg, MemOrIOtoReg, ALUSrc, RegWrite, IOReadUnsigned, IOReadSigned, IOWrite;
    wire [31:0] inst;
    wire [31:0] imm32;





endmodule