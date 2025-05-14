`timescale 1ns / 1ps

module Tube(
    input clk,                  // CPU clock
    input fpgaClk,              // FPGA base clock
    input rst,                  // Reset signal
    input ioWrite,              // I/O write enable
    input tubeCtrl,             // Tube chip select
    input [7:0] tubeAddr,       // Address for display selection
    input [15:0] tubeWdata,     // 16-bit data to display
    input [31:0] tubeWdata32,   // 32-bit data to display
    
    output reg [7:0] sel,       // Digit select signals
    output reg [7:0] tube0,     // Segment pattern for upper digits
    output reg [7:0] tube1      // Segment pattern for lower digits
);

    // Internal registers
    reg [18:0] divClkCnt = 0;     // Initialize counter
    reg divClk = 0;               // Initialize divided clock
    reg [3:0] dispDat = 0;        // Initialize display data
    reg [2:0] dispBit = 0;        // Initialize bit counter
    reg [31:0] data = 0;          // Initialize data register
    
    // Initialize digit registers
    reg [3:0] num0 = 0, num1 = 0, num2 = 0, num3 = 0;
    reg [3:0] num4 = 0, num5 = 0, num6 = 0, num7 = 0;

    // Clock divider (using shorter count for simulation)
    always @(posedge fpgaClk) begin
        if (!rst) begin
            divClkCnt <= 0;
            divClk <= 0;
        end
        else if (divClkCnt >= 4) begin  // Short count for simulation
            divClk <= ~divClk;
            divClkCnt <= 0;
        end
        else begin
            divClkCnt <= divClkCnt + 1;
        end
    end

    // Data input handling
    always @(posedge fpgaClk) begin
        if (!rst) begin
            data <= 32'h0;
        end
        else if (tubeCtrl && ioWrite) begin
            data <= tubeWdata32;
        end
    end

    // Digit value update
    always @(posedge clk) begin
        if (!rst) begin
            {num7,num6,num5,num4,num3,num2,num1,num0} <= 32'h0;
        end
        else begin
            num7 <= data[31:28];
            num6 <= data[27:24];
            num5 <= data[23:20];
            num4 <= data[19:16];
            num3 <= data[15:12];
            num2 <= data[11:8];
            num1 <= data[7:4];
            num0 <= data[3:0];
        end
    end

    // Display multiplexing and segment pattern generation
    always @(posedge divClk) begin
        if (!rst) begin
            dispBit <= 0;
            sel <= 8'h00;
            dispDat <= 4'h0;
            tube0 <= 8'h00;
            tube1 <= 8'h00;
        end
        else begin
            // Update display selection and current digit
            case (dispBit)
                3'b000: begin dispDat <= num0; sel <= 8'b00000001; end
                3'b001: begin dispDat <= num1; sel <= 8'b00000010; end
                3'b010: begin dispDat <= num2; sel <= 8'b00000100; end
                3'b011: begin dispDat <= num3; sel <= 8'b00001000; end
                3'b100: begin dispDat <= num4; sel <= 8'b00010000; end
                3'b101: begin dispDat <= num5; sel <= 8'b00100000; end
                3'b110: begin dispDat <= num6; sel <= 8'b01000000; end
                3'b111: begin dispDat <= num7; sel <= 8'b10000000; end
            endcase
            
            // Update segment patterns
            if (sel > 8'b00001000) begin
                case (dispDat)
                    4'h0: tube0 <= 8'hfc;
                    4'h1: tube0 <= 8'h60;
                    4'h2: tube0 <= 8'hda;
                    4'h3: tube0 <= 8'hf2;
                    4'h4: tube0 <= 8'h66;
                    4'h5: tube0 <= 8'hb6;
                    4'h6: tube0 <= 8'hbe;
                    4'h7: tube0 <= 8'he0;
                    4'h8: tube0 <= 8'hfe;
                    4'h9: tube0 <= 8'hf6;
                    4'ha: tube0 <= 8'hee;
                    4'hb: tube0 <= 8'h3e;
                    4'hc: tube0 <= 8'h9c;
                    4'hd: tube0 <= 8'h7a;
                    4'he: tube0 <= 8'h9e;
                    4'hf: tube0 <= 8'h8e;
                    default: tube0 <= 8'h00;
                endcase
                tube1 <= 8'h00;  // Clear lower segments when showing upper
            end
            else begin
                case (dispDat)
                    4'h0: tube1 <= 8'hfc;
                    4'h1: tube1 <= 8'h60;
                    4'h2: tube1 <= 8'hda;
                    4'h3: tube1 <= 8'hf2;
                    4'h4: tube1 <= 8'h66;
                    4'h5: tube1 <= 8'hb6;
                    4'h6: tube1 <= 8'hbe;
                    4'h7: tube1 <= 8'he0;
                    4'h8: tube1 <= 8'hfe;
                    4'h9: tube1 <= 8'hf6;
                    4'ha: tube1 <= 8'hee;
                    4'hb: tube1 <= 8'h3e;
                    4'hc: tube1 <= 8'h9c;
                    4'hd: tube1 <= 8'h7a;
                    4'he: tube1 <= 8'h9e;
                    4'hf: tube1 <= 8'h8e;
                    default: tube1 <= 8'h00;
                endcase
                tube0 <= 8'h00;  // Clear upper segments when showing lower
            end
            
            dispBit <= dispBit + 1;
        end
    end

endmodule