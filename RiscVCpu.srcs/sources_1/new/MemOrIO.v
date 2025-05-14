`timescale 1ns / 1ps

module MemOrIO(
    // Control signals
    input mRead,                // Memory read enable
    input mWrite,               // Memory write enable
    input ioReadUnsigned,       // Unsigned I/O read enable
    input ioReadSigned,         // Signed I/O read enable
    input ioWrite,              // I/O write enable
    
    // Address and data buses
    input [31:0] addrIn,        // Address from ALU
    input [31:0] mRdata,        // Data read from memory
    input [15:0] ioRdata,       // Data read from I/O devices
    input [31:0] rRdata,        // Data from register file (for writes)
    
    // Output connections
    output [31:0] addrOut,      // Address to memory and I/O devices
    output reg [31:0] rWdata,   // Data to register file
    output reg [31:0] writeData,     // Data to memory/I/O
    output reg [31:0] writeData32,   // Original 32-bit data for I/O devices
    
    // Peripheral select signals
    output switchCtrl,          // Switch input control
    output ledCtrl,             // LED output control
    output tubeCtrl             // 7-segment display control
);

    // Define peripheral address ranges
    localparam IO_ADDRESS_HIGH = 22'h3FFFFF;  // Top 22 bits for I/O addresses
    
    // Address ranges for specific peripherals (lower 8 bits)
    localparam SWITCH_ADDR_RANGE_START = 8'h00;
    localparam SWITCH_ADDR_RANGE_END = 8'h2F;
    
    localparam LED_ADDR_RANGE_START = 8'h30;
    localparam LED_ADDR_RANGE_END = 8'h5F;
    
    localparam TUBE_ADDR_RANGE_START = 8'h60;
    localparam TUBE_ADDR_RANGE_END = 8'h7F;

    // Pass address directly to memory and I/O
    assign addrOut = addrIn;
    
    // Generate chip select signals based on address range and I/O operation
    assign switchCtrl = (ioReadSigned || ioReadUnsigned) && 
                       (addrIn[7:0] >= SWITCH_ADDR_RANGE_START && 
                        addrIn[7:0] <= SWITCH_ADDR_RANGE_END);
    
    assign ledCtrl = ioWrite && (addrIn[7:0] >= LED_ADDR_RANGE_START && 
                                addrIn[7:0] <= LED_ADDR_RANGE_END);
    
    assign tubeCtrl = ioWrite && (addrIn[7:0] >= TUBE_ADDR_RANGE_START && 
                                  addrIn[7:0] <= TUBE_ADDR_RANGE_END);

    // Data handling for register writeback
    always @(*) begin
        // Default to memory data
        rWdata = mRdata;
        
        // Handle I/O reads with proper extension
        if (ioReadUnsigned || ioReadSigned) begin
            case (addrIn[7:0])
                // Main 16-bit input (all switches)
                SWITCH_ADDR_RANGE_START: begin
                    if (ioReadUnsigned)
                        rWdata = {16'h0000, ioRdata};          // Zero-extend
                    else
                        rWdata = {{16{ioRdata[15]}}, ioRdata}; // Sign-extend
                end
                
                // Upper 8 switches
                SWITCH_ADDR_RANGE_START + 8'h10: begin
                    if (ioReadUnsigned)
                        rWdata = {24'h000000, ioRdata[7:0]};    // Zero-extend
                    else
                        rWdata = {{24{ioRdata[7]}}, ioRdata[7:0]}; // Sign-extend
                end
                
                // Buttons (use bottom 4 bits only)
                SWITCH_ADDR_RANGE_START + 8'h20, 
                SWITCH_ADDR_RANGE_START + 8'h24, 
                SWITCH_ADDR_RANGE_START + 8'h28, 
                SWITCH_ADDR_RANGE_START + 8'h2C: begin
                    rWdata = {28'b0, ioRdata[3:0]};            // Always zero-extend buttons
                end
                
                default: rWdata = mRdata;                      // Default to memory data
            endcase
        end
    end

    // Data preparation for memory/I/O writes
    always @(*) begin
        if (mWrite || ioWrite) begin
            // For memory writes, use the full 32-bit value
            // For I/O writes, sign-extend the lower 16 bits for compatibility
            writeData = mWrite ? rRdata : {{16{rRdata[15]}}, rRdata[15:0]};
            
            // Always preserve the original 32-bit data for devices that need it
            writeData32 = rRdata;
        end
        else begin
            // High impedance when not writing
            writeData = 32'hZZZZZZZZ;
            writeData32 = 32'hZZZZZZZZ;
        end
    end

endmodule