`timescale 1ns / 1ps

module Led(
    input clk,                  // Clock signal
    input rst,                  // Reset signal (active low)
    input IOWrite,              // I/O write enable
    input LEDCtrl,              // LED chip select
    input [7:0] ledaddr,        // Address for LED selection
    input [15:0] ledwdata,      // Data to write to LEDs
    output reg [15:0] led       // Physical LED outputs
);

    // Define LED address mappings
    localparam ALL_LEDS_ADDR = 8'h30;     // All 16 LEDs
    localparam LEFT_LEDS_ADDR = 8'h40;    // Left 8 LEDs
    localparam RIGHT_LEDS_ADDR = 8'h50;   // Right 8 LEDs
    localparam SINGLE_LED_BASE_ADDR = 8'h58; // Base for individual LED control

    // LED control logic
    always @(negedge clk or negedge rst) begin
        if (~rst) begin
            // Clear all LEDs on reset
            led <= 16'h0000;
        end
        else if (LEDCtrl && IOWrite) begin
            // Address decoding for different LED groups
            case (ledaddr)
                ALL_LEDS_ADDR:
                    led <= ledwdata;                   // Control all 16 LEDs
                
                LEFT_LEDS_ADDR:
                    led <= {ledwdata[7:0], led[7:0]};  // Control left 8 LEDs
                
                RIGHT_LEDS_ADDR:
                    led <= {led[15:8], ledwdata[7:0]}; // Control right 8 LEDs
                
                // Additional feature: individual LED control
                SINGLE_LED_BASE_ADDR:
                    led[0] <= ledwdata[0];            // Control LED 0
                
                SINGLE_LED_BASE_ADDR + 8'h01:
                    led[1] <= ledwdata[0];            // Control LED 1
                
                // More individual LED controls can be added here
                
                default:
                    led <= led;                       // Maintain current state
            endcase
        end
        else begin
            // Hold current state when not writing
            led <= led;
        end
    end

endmodule