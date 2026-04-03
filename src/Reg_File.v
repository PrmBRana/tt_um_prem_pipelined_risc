`default_nettype none
`timescale 1ns / 1ps

module Reg_file (
    input  wire        clk,
    input  wire        reset,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire        Regwrite,
    input  wire [31:0] Write_data,
    output wire [31:0] Read_data1,
    output wire [31:0] Read_data2
);

    integer k;
    reg [31:0] Register [0:31];

    // FIX: Added 'or posedge reset' to match the rest of your pipeline
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (k = 0; k < 32; k = k + 1)
                Register[k] <= 32'd0;
        end
        else if (Regwrite && rd_addr != 5'd0) begin
            Register[rd_addr] <= Write_data;
        end
    end

    // Combinational read with write-then-read forwarding (Standard Bypass)
    assign Read_data1 = (rs1_addr == 5'd0)                    ? 32'd0      :
                        (Regwrite && rd_addr == rs1_addr)      ? Write_data :
                        Register[rs1_addr];

    assign Read_data2 = (rs2_addr == 5'd0)                    ? 32'd0      :
                        (Regwrite && rd_addr == rs2_addr)      ? Write_data :
                        Register[rs2_addr];

endmodule
