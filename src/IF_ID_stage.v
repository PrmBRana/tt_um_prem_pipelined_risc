`default_nettype none
`timescale 1ns / 1ps

module IF_ID_stage (
    input wire        clk,
    input wire        reset,
    input wire        stallD,
    input wire        flushD,
    input wire [31:0] PC_in,
    input wire [31:0] PCplus4_in,
    input wire [31:0] instruction_in,
    output reg [31:0] instruction_out,
    output reg [31:0] PCplus4_out,
    output reg [31:0] PC_out
);

    // FIX: Added 'or posedge reset' for consistency across the 8x2 tile
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instruction_out <= 32'h00000013; // RISC-V NOP (addi x0, x0, 0)
            PCplus4_out     <= 32'b0;
            PC_out          <= 32'b0;
        end
        else if (flushD) begin
            // Insert NOP bubble — clear everything
            instruction_out <= 32'h00000013;
            PCplus4_out     <= 32'b0;
            PC_out          <= 32'b0;
        end
        else if (!stallD) begin
            // Normal pipeline advance
            instruction_out <= instruction_in;
            PCplus4_out     <= PCplus4_in;
            PC_out          <= PC_in;
        end
        // Implicit stall: registers hold their value
    end
endmodule
