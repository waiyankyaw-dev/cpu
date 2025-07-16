`timescale 1ns / 1ps

module Switch(
    input clk,                  // Clock signal
    input rst,                 // Reset signal (active low)
    input ioReadUnsigned,       // Unsigned read control
    input ioReadSigned,        // Signed read control
    input switchCtrl,           // Switch chip select
    input [11:0] switch,        //12 swithches
    input [3:0] button,         // 4 physical buttons
    input [7:0] switchAddr,     // Address to select specific input
    output reg [15:0] switchReadData // Data output to CPU 
);

    //  specific button/switch address mappings
    localparam FULL_SWITCH_ADDR = 8'h00;     // 12 switches
    localparam UPPER_SWITCH_ADDR = 8'h10;   // Upper 8 switches
    localparam TEST_BUTTON_ADDR = 8'h20;      // Test case button
    localparam RESET_BUTTON_ADDR = 8'h24;   // Reset/end test button
    localparam INPUT_A_BUTTON_ADDR = 8'h28;  // Input A button
    localparam INPUT_B_BUTTON_ADDR = 8'h2C;  // Input B button

    // Register input data based on address
    always @(negedge clk or negedge rst) begin
        if (~rst) begin
            // Reset output to zero
            switchReadData <= 16'h0000;
        end
        else if (switchCtrl && (ioReadUnsigned || ioReadSigned)) begin
            // Address decoding for different inputs
            case (switchAddr)
                FULL_SWITCH_ADDR: 
                    switchReadData <= {4'b0000, switch};         // Zero-extend 12-bit switches to 16 bits
                
                UPPER_SWITCH_ADDR: 
                    switchReadData <= {8'h00, switch[11:4]};     // Read upper 8 bits of 12-bit switches
                
                TEST_BUTTON_ADDR: 
                    switchReadData <= {15'b0, button[3]};   // Test case button
                
                RESET_BUTTON_ADDR: 
                    switchReadData <= {15'b0, button[2]};      // Reset button
                
                INPUT_A_BUTTON_ADDR: 
                    switchReadData <= {15'b0, button[0]};    // Input A button
                
                INPUT_B_BUTTON_ADDR: 
                    switchReadData <= {15'b0, button[1]};  // Input B button
                
                default: 
                    switchReadData <= switchReadData;           
            endcase
        end
        else begin
            switchReadData <= switchReadData;
        end
    end
endmodule