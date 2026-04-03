`default_nettype none
`timescale 1ns / 1ps

module mem1KB_32bit (
    input  wire        clk,
    input  wire        reset,      // Added Reset for physical stability
    input  wire        we,         // Write Enable from Bootloader
    input  wire [7:0]  addr,       // Address from Bootloader
    input  wire [31:0] wdata,      // Data from Bootloader
    input  wire [31:0] read_Address,// Address from Program Counter (PC)
    output wire [31:0] Instruction_out
);

    // Silence unused bits of the 32-bit PC address
    wire _unused = &{1'b0, read_Address[31:8], read_Address[1:0]}; 

    localparam integer DEPTH = 64;  // 64 words * 4 bytes = 256 Bytes
    reg [31:0] mem [0:DEPTH-1];
    integer i;

    // --- Synchronous Write & Reset ---
    // Using a simple loop for reset helps the tool map to 
    // standard cells in the 8x2 tile.
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= 32'h00000013; // Reset to NOP (addi x0, x0, 0)
            end
        end else if (we && addr < DEPTH) begin
            // Write using bits [5:0] (0 to 63)
            mem[addr[5:0]] <= wdata;
        end
    end

    // --- Combinational Read (Matches your simulation) ---
    // Note: For 50MHz, if timing fails, move this inside an 'always @(posedge clk)'
    // Using [7:2] correctly aligns the 32-bit word with a byte-addressed PC.
    assign Instruction_out = mem[read_Address[7:2]];

endmodule
