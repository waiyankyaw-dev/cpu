`timescale 1ns / 1ps

module Led(
    input clk,                  // Clock signal
    input rst,                  // Reset signal (active low)
    input ioWrite,              // I/O write enable
    input ledCtrl,              // LED chip select
    input [7:0] ledAddr,        // Address for LED selection
    input [15:0] ledWdata,      // Data to write to LEDs
    output reg [15:0] led       // Physical LED outputs
);

    //  LED address mappings
    localparam ALL_LEDS_ADDR = 8'h30;     // All 16 LEDs
    localparam LEFT_LEDS_ADDR = 8'h40;    // Left 8 LEDs
    localparam RIGHT_LEDS_ADDR = 8'h50;   // Right 8 LEDs
    localparam SINGLE_LED_BASE_ADDR = 8'h58; // Base for individual LED control

    always @(negedge clk or negedge rst) begin
        if (~rst) begin
            led <= 16'h0000;
        end
        else if (ledCtrl && ioWrite) begin
            // Address decoding for different LED groups
            case (ledAddr)
                ALL_LEDS_ADDR:
                    led <= ledWdata;                   // Control all 16 LEDs
                
                LEFT_LEDS_ADDR:
                    led <= {ledWdata[7:0], 8'b0};      // Control left 8 LEDs
                
                RIGHT_LEDS_ADDR:
                    led <= {8'b0, ledWdata[7:0]};      // Control right 8 LEDs
                
                // Additional feature: individual LED control
                SINGLE_LED_BASE_ADDR:
                    led <= {15'b0, ledWdata[0]};       // Control LED 0
                
                SINGLE_LED_BASE_ADDR + 8'h01:
                    led <= {14'b0, ledWdata[0], 1'b0}; // Control LED 1
                
                // More individual LED controls can be added here
                
                default:
                    led <= led;                        // Maintaining current state
            endcase
        end
        else begin
            led <= led;
        end
    end

endmodule