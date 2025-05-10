`timescale 1ns / 1ps

module Tube(
    input clk,                  // CPU clock
    input fpga_clk,             // FPGA base clock (faster)
    input rst,                  // Reset signal (active low)
    input clk_div_2s,           // Slow clock for sequential display
    input button,               // Test case button
    input button2,              // Reset button
    input IOWrite,              // I/O write enable
    input TubeCtrl,             // Tube chip select
    input [7:0] tubeaddr,       // Address for display selection
    input [15:0] tubewdata,     // 16-bit data to display
    input [31:0] tubewdata32,   // 32-bit data to display
    input [15:0] testcase,      // Test case identifier
    output reg [7:0] sel,       // Digit select signals
    output reg [7:0] tube0,     // Segment pattern for upper digits
    output reg [7:0] tube1      // Segment pattern for lower digits
);

    // Display address mappings
    localparam NORMAL_DISPLAY_ADDR = 8'h60;       // Regular display
    localparam SIGNED_DISPLAY_ADDR = 8'h68;       // Signed display
    localparam SEQUENTIAL_DISPLAY_ADDR = 8'h64;   // Address for sequential display
    localparam SPECIAL_TEST_ID = 16'h0007;        // Special test case identifier

    // Display constants
    localparam DISPLAY_REFRESH_DIVIDER = 50000;   // Refresh rate divider
    localparam MAX_SEQUENCE_LENGTH = 192;         // Maximum sequence length

    // Internal registers
    reg [18:0] divclk_cnt;          // Clock divider counter
    reg divclk;                     // Divided clock for display refresh
    reg [3:0] disp_dat;             // Current digit value to display
    reg [2:0] disp_bit;             // Current display position (0-7)
    reg [3:0] num0, num1, num2, num3, num4, num5, num6, num7; // Digit values
    reg [31:0] data;                // Current display data
    reg [31:0] dataSlow;            // Data for slow sequential display
    reg testMode;                   // Test mode flag
    reg [31:0] sequence [0:MAX_SEQUENCE_LENGTH-1]; // Sequence buffer
    integer seq_write_index;        // Write position in sequence
    integer seq_read_index;         // Read position in sequence
    integer i;                      // Loop counter

    // Clock divider for display refresh
    always @(posedge fpga_clk) begin
        if (divclk_cnt == DISPLAY_REFRESH_DIVIDER) begin
            divclk <= ~divclk;
            divclk_cnt <= 0;
        end else begin
            divclk_cnt <= divclk_cnt + 1'b1;
        end
    end

    // Test mode detection
    always @(posedge fpga_clk or negedge rst) begin
        if (~rst) begin
            testMode <= 1'b0;
        end
        else if (testcase == SPECIAL_TEST_ID) begin
            testMode <= 1'b1;
        end
        else if (button2) begin
            testMode <= 1'b0;
        end
        else begin
            testMode <= testMode;
        end
    end

    // Sequence buffer management
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            seq_write_index <= 0;
            for (i = 0; i < MAX_SEQUENCE_LENGTH; i = i + 1) begin
                sequence[i] <= 0;
            end
        end
        else if (tubeaddr == SEQUENTIAL_DISPLAY_ADDR && testMode) begin
            // Store data in sequence buffer
            sequence[seq_write_index] <= tubewdata32;
            seq_write_index <= seq_write_index + 1;
        end
        else if (button2) begin
            // Reset sequence on button press
            seq_write_index <= 0;
            for (i = 0; i < MAX_SEQUENCE_LENGTH; i = i + 1) begin
                sequence[i] <= 0;
            end
        end
    end

    // Sequence playback control
    always @(posedge clk_div_2s or negedge rst) begin
        if (~rst) begin
            seq_read_index <= 0;
            dataSlow <= 32'b0;
        end
        else if (testMode && sequence[seq_read_index] != 32'b0) begin
            // Advance through non-zero sequence entries
            seq_read_index <= seq_read_index + 1;
        end
        else if (button2) begin
            seq_read_index <= 0;
        end
        
        // Update slow data from sequence
        dataSlow <= sequence[seq_read_index];
    end

    // Display data selection
    always @(posedge fpga_clk or negedge rst) begin
        if (~rst) begin
            data <= 32'b0;
        end
        else if (testMode) begin
            // In test mode, display data from sequence
            data <= dataSlow;
        end
        else if (testMode == 1'b0) begin
            if (tubeaddr == SIGNED_DISPLAY_ADDR) begin
                // Sign-extend 16-bit data
                data <= {{16{tubewdata[15]}}, tubewdata[15:0]};
            end
            else begin
                // Use full 32-bit data
                data <= tubewdata32;
            end
        end
    end

    // Update display digits
    always @(negedge clk or negedge rst) begin
        if (~rst) begin
            // Default display shows "ABCD-0000"
            num7 <= 4'hA;
            num6 <= 4'hB;
            num5 <= 4'hC;
            num4 <= 4'hD;
            num3 <= 4'h0;
            num2 <= 4'h0;
            num1 <= 4'h0;
            num0 <= 4'h0;
        end
        else if ((TubeCtrl == 1'b1 && IOWrite == 1'b1) || dataSlow != 32'b0) begin
            // Update all 8 digits from 32-bit data
            num7 <= data[31:28];
            num6 <= data[27:24];
            num5 <= data[23:20];
            num4 <= data[19:16];
            num3 <= data[15:12];
            num2 <= data[11:8];
            num1 <= data[7:4];
            num0 <= data[3:0];
        end
        else begin
            // Maintain current display
            num7 <= num7;
            num6 <= num6;
            num5 <= num5;
            num4 <= num4;
            num3 <= num3;
            num2 <= num2;
            num1 <= num1;
            num0 <= num0;
        end
    end

    // Display multiplexing
    always @(posedge divclk) begin
        if (disp_bit > 7) begin
            disp_bit <= 0;
        end
        else begin
            disp_bit <= disp_bit + 1'b1;
            case (disp_bit)
                3'b000: begin disp_dat <= num0; sel <= 8'b00000001; end
                3'b001: begin disp_dat <= num1; sel <= 8'b00000010; end
                3'b010: begin disp_dat <= num2; sel <= 8'b00000100; end
                3'b011: begin disp_dat <= num3; sel <= 8'b00001000; end
                3'b100: begin disp_dat <= num4; sel <= 8'b00010000; end
                3'b101: begin disp_dat <= num5; sel <= 8'b00100000; end
                3'b110: begin disp_dat <= num6; sel <= 8'b01000000; end
                3'b111: begin disp_dat <= num7; sel <= 8'b10000000; end
                default: begin disp_dat <= 0; sel <= 8'b00000000; end
            endcase
        end
    end

    // 7-segment pattern generation
    always @(disp_dat) begin
        if (sel > 8'b00001000) begin
            // Upper 4 digits (tube0)
            case (disp_dat)
                4'h0: tube0 = 8'hfc; // "0" pattern
                4'h1: tube0 = 8'h60; // "1" pattern
                4'h2: tube0 = 8'hda; // "2" pattern
                4'h3: tube0 = 8'hf2; // "3" pattern
                4'h4: tube0 = 8'h66; // "4" pattern
                4'h5: tube0 = 8'hb6; // "5" pattern
                4'h6: tube0 = 8'hbe; // "6" pattern
                4'h7: tube0 = 8'he0; // "7" pattern
                4'h8: tube0 = 8'hfe; // "8" pattern
                4'h9: tube0 = 8'hf6; // "9" pattern
                4'ha: tube0 = 8'hee; // "A" pattern
                4'hb: tube0 = 8'h3e; // "b" pattern
                4'hc: tube0 = 8'h9c; // "C" pattern
                4'hd: tube0 = 8'h7a; // "d" pattern
                4'he: tube0 = 8'h9e; // "E" pattern
                4'hf: tube0 = 8'h8e; // "F" pattern
            endcase
        end
        else begin
            // Lower 4 digits (tube1)
            case (disp_dat)
                4'h0: tube1 = 8'hfc; // "0" pattern
                4'h1: tube1 = 8'h60; // "1" pattern
                4'h2: tube1 = 8'hda; // "2" pattern
                4'h3: tube1 = 8'hf2; // "3" pattern
                4'h4: tube1 = 8'h66; // "4" pattern
                4'h5: tube1 = 8'hb6; // "5" pattern
                4'h6: tube1 = 8'hbe; // "6" pattern
                4'h7: tube1 = 8'he0; // "7" pattern
                4'h8: tube1 = 8'hfe; // "8" pattern
                4'h9: tube1 = 8'hf6; // "9" pattern
                4'ha: tube1 = 8'hee; // "A" pattern
                4'hb: tube1 = 8'h3e; // "b" pattern
                4'hc: tube1 = 8'h9c; // "C" pattern
                4'hd: tube1 = 8'h7a; // "d" pattern
                4'he: tube1 = 8'h9e; // "E" pattern
                4'hf: tube1 = 8'h8e; // "F" pattern
            endcase
        end
    end

endmodule