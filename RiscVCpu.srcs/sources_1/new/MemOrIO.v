`timescale 1ns / 1ps

module MemOrIO(
    // Control signals
    input mRead,                // Memory read enable
    input mWrite,               // Memory write enable
    input IOReadUnsigned,       // Unsigned I/O read enable
    input IOReadSigned,         // Signed I/O read enable
    input IOWrite,              // I/O write enable
    
    // Address and data buses
    input [31:0] addr_in,       // Address from ALU
    input [31:0] m_rdata,       // Data read from memory
    input [15:0] io_rdata,      // Data read from I/O devices(from switch)
    input [31:0] r_rdata,       // Data from register file (for writes)
    
    // Output connections
    output [31:0] addr_out,     // Address to memory and I/O devices
    output reg [31:0] r_wdata,  // write Data to register file
    output reg [31:0] write_data,     // Data to memory or I/O (potentially sign-extended) <write to IO device, store>
    output reg [31:0] write_data_32,  // Original 32-bit data for I/O devices
    
    // Peripheral select signals
    output SwitchCtrl,          // Switch input control
    output LEDCtrl,             // LED output control
    output TubeCtrl             // 7-segment display control
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
    
    // Special address for sequential display
//    localparam TUBE_SPECIAL_ADDR = 8'h64;

    // Pass address directly to memory and I/O
    assign addr_out = addr_in;
    
    // Generate chip select signals based on address range and I/O operation
    //input
    assign SwitchCtrl = (IOReadSigned || IOReadUnsigned) && 
                       (addr_in[7:0] >= SWITCH_ADDR_RANGE_START && 
                        addr_in[7:0] <= SWITCH_ADDR_RANGE_END);

    //output
    
    assign LEDCtrl = IOWrite && (addr_in[7:0] >= LED_ADDR_RANGE_START && 
                                addr_in[7:0] <= LED_ADDR_RANGE_END);
    
    assign TubeCtrl = IOWrite && (addr_in[7:0] >= TUBE_ADDR_RANGE_START && 
                                  addr_in[7:0] <= TUBE_ADDR_RANGE_END);

    // Data handling for register writeback (read from memory of I/O) (load)
    always @(*) begin
        // Default to memory data
        r_wdata = m_rdata;
        
        // Handle I/O reads with proper extension
        if (IOReadUnsigned || IOReadSigned) begin
            case (addr_in[7:0])
                // Main 16-bit input (all switches)
                SWITCH_ADDR_RANGE_START: begin
                    if (IOReadUnsigned)
                        r_wdata = {16'h0000, io_rdata};          // Zero-extend
                    else
                        r_wdata = {{16{io_rdata[15]}}, io_rdata}; // Sign-extend
                end
                
                // Upper 8 switches
                SWITCH_ADDR_RANGE_START + 8'h10: begin
                    if (IOReadUnsigned)
                        r_wdata = {24'h000000, io_rdata[7:0]};    // Zero-extend
                    else
                        r_wdata = {{24{io_rdata[7]}}, io_rdata[7:0]}; // Sign-extend
                end
                
                // Buttons (use bottom 4 bits only)
                SWITCH_ADDR_RANGE_START + 8'h20, //Test case button (button[3])
                SWITCH_ADDR_RANGE_START + 8'h24, //Reset button (button[2])
                SWITCH_ADDR_RANGE_START + 8'h28, //Input A button (button[0])
                SWITCH_ADDR_RANGE_START + 8'h2C: begin //Input B button (button[1])
                    r_wdata = {28'b0, io_rdata[3:0]};            // Always zero-extend buttons
                end
                
                default: r_wdata = m_rdata;                      // Default to memory data
            endcase
        end
    end

    // Data preparation for memory/I/O writes
    always @(*) begin
        if (mWrite || IOWrite) begin
            // For memory writes, use the full 32-bit value
            // For I/O writes, sign-extend the lower 16 bits for compatibility
            write_data = mWrite ? r_rdata : {{16{r_rdata[15]}}, r_rdata[15:0]};
            
            // Always preserve the original 32-bit data for devices that need it
            write_data_32 = r_rdata;
        end
        else begin
            // High impedance when not writing
            write_data = 32'hZZZZZZZZ;
            write_data_32 = 32'hZZZZZZZZ;
        end
    end

endmodule