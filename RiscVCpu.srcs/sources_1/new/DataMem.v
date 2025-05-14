`timescale 1ns / 1ps

module DataMem(
    input clk, 
    input memWrite, 
    input memRead,
    input [31:0] addr, 
    input [31:0] din, 
    output [31:0] dout 
);
    
    RAM udram(.clka(~clk), .wea(memWrite), .addra(addr[15:2]), .dina(din), .douta(dout));

endmodule