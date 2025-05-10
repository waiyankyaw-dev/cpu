`timescale 1ns / 1ps

module Switch(
    input clk,                  // Clock signal
    input rst,                  // Reset signal (active low)
    input IOReadUnsigned,       // Unsigned read control
    input IOReadSigned,         // Signed read control
    input SwitchCtrl,           // Switch chip select
    input [15:0] switch,        // 16 physical switches
    input [3:0] button,         // 4 physical buttons
    input [7:0] switchaddr,     // Address to select specific input
    output reg [15:0] switchrdata // Data output to CPU
);

    // Define specific button/switch address mappings
    localparam FULL_SWITCH_ADDR = 8'h00;     // All 16 switches
    localparam UPPER_SWITCH_ADDR = 8'h10;    // Upper 8 switches
    localparam TEST_BUTTON_ADDR = 8'h20;     // Test case button
    localparam RESET_BUTTON_ADDR = 8'h24;    // Reset/end test button
    localparam INPUT_A_BUTTON_ADDR = 8'h28;  // Input A button
    localparam INPUT_B_BUTTON_ADDR = 8'h2C;  // Input B button

    // Register input data based on address
    always @(negedge clk or negedge rst) begin
        if (~rst) begin
            // Reset output to zero
            switchrdata <= 16'h0000;
        end
        else if (SwitchCtrl && (IOReadUnsigned || IOReadSigned)) begin
            // Address decoding for different inputs
            case (switchaddr)
                FULL_SWITCH_ADDR: 
                    switchrdata <= switch;                     // Read all 16 switches
                
                UPPER_SWITCH_ADDR: 
                    switchrdata <= {8'h00, switch[15:8]};      // Read upper 8 switches
                
                TEST_BUTTON_ADDR: 
                    switchrdata <= {15'b0, button[3]};         // Test case button
                
                RESET_BUTTON_ADDR: 
                    switchrdata <= {15'b0, button[2]};         // Reset button
                
                INPUT_A_BUTTON_ADDR: 
                    switchrdata <= {15'b0, button[0]};         // Input A button
                
                INPUT_B_BUTTON_ADDR: 
                    switchrdata <= {15'b0, button[1]};         // Input B button
                
                default: 
                    switchrdata <= switchrdata;                // Maintain current value
            endcase
        end
        else begin
            // Hold current value when not selected
            switchrdata <= switchrdata;
        end
    end

endmodule