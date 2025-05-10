`timescale 1ns / 1ps

module Decoder(
    input clk,
    input rst,
    input [31:0] ALU_result,
    input MemOrIOtoReg,
    input regWrite,
    input [31:0] inst,
    input [31:0] ra,
    input jump,
    input [31:0] IOData,
    input IOReadSigned,      
    input IOReadUnsigned,    
    output [31:0] rs1Data,
    output [31:0] rs2Data,
    output reg [31:0] imm32
);

    // Change to match reference style
    reg [31:0] registers [31:0];  // Changed from [0:31] to [31:0] to match reference
    wire [4:0] writeReg;
    reg [31:0] writeData;
    integer i;

    // Simplified register addressing like reference
    assign writeReg = inst[11:7];
    assign rs1Data = registers[inst[19:15]];  // Removed lui check to match reference
    assign rs2Data = registers[inst[24:20]];
    
    // Write data selection
    always @* begin
        if(MemOrIOtoReg) begin
            if(IOReadSigned) begin
                if(inst[14:12] == 3'b000)
                    writeData = {{24{IOData[7]}}, IOData[7:0]};
                else
                    writeData = IOData;
            end
            else if(IOReadUnsigned)
                writeData = {24'b0, IOData[7:0]};
            else
                writeData = IOData;
        end
        else if(jump)
            writeData = ra;
        else
            writeData = ALU_result;
    end

    // Register file handling - matched to reference style
    always @(posedge clk) begin
        if (!rst) begin  // Changed to match reference (!rst instead of ~rst)
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'h0;
        end
        else if (regWrite && writeReg != 0) begin  // Changed condition to match reference
            registers[writeReg] <= writeData;
        end
    end

    // Immediate generation - reorganized to match reference style
    always @(*) begin
        case(inst[6:0])
            // I-type instructions grouped together
            7'b0010011,  // arithmetic
            7'b0000011,  // load
            7'b1100111:  // jalr
                imm32 = {{20{inst[31]}}, inst[31:20]};
            
            // S-type
            7'b0100011:  // store
                imm32 = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            
            // B-type
            7'b1100011:  // branch
                imm32 = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            
            // U-type
            7'b0110111,  // lui
            7'b0010111:  // auipc
                imm32 = {inst[31:12], 12'b0};
            
            // J-type
            7'b1101111:  // jal
                imm32 = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            
            default:
                imm32 = 32'b0;
        endcase
    end

endmodule
