`default_nettype none
`timescale 1ns / 1ps

module Hazard_Unit (
    input  wire [4:0]  Rs1D,
    input  wire [4:0]  Rs2D,
    input  wire [4:0]  Rs1E,
    input  wire [4:0]  Rs2E,
    input  wire [4:0]  RdE,
    input  wire        RegWriteE,
    input  wire [1:0]  ResultSrcE_in,
    input  wire [4:0]  RdM,
    input  wire        RegWriteM,
    input  wire [4:0]  RdW,
    input  wire        RegWriteW,
    input  wire        PCSRCE,
    output reg         StallF,
    output reg         StallD,
    output reg         FlushD,
    output reg         FlushE,
    output reg  [1:0]  Forward_AE,
    output reg  [1:0]  Forward_BE
);

    // 1. Forwarding Logic (Flattened for Speed)
    // Priority: Memory Stage (RdM) > Writeback Stage (RdW)
    always @(*) begin
        // Default: No forwarding
        Forward_AE = 2'b00;
        Forward_BE = 2'b00;

        // Forward A logic
        if ((Rs1E != 5'b0) && RegWriteM && (Rs1E == RdM)) begin
            Forward_AE = 2'b10; // Forward from Memory Stage
        end else if ((Rs1E != 5'b0) && RegWriteW && (Rs1E == RdW)) begin
            Forward_AE = 2'b01; // Forward from Writeback Stage
        end

        // Forward B logic
        if ((Rs2E != 5'b0) && RegWriteM && (Rs2E == RdM)) begin
            Forward_BE = 2'b10; // Forward from Memory Stage
        end else if ((Rs2E != 5'b0) && RegWriteW && (Rs2E == RdW)) begin
            Forward_BE = 2'b01; // Forward from Writeback Stage
        end
    end

    // 2. Hazard Detection Logic (Stalls and Flushes)
    // ResultSrcE_in == 2'b01 indicates a LOAD instruction (lw)
    wire lw_stall = (ResultSrcE_in == 2'b01) && 
                    ((Rs1D == RdE) || (Rs2D == RdE)) && 
                    (RdE != 5'b0);

    always @(*) begin
        // Defaults
        StallF = 1'b0;
        StallD = 1'b0;
        FlushE = 1'b0;
        FlushD = 1'b0;

        // Handle Stalls (Load-Use Hazard)
        if (lw_stall) begin
            StallF = 1'b1;
            StallD = 1'b1;
            FlushE = 1'b1; // Insert a bubble in Execute
        end

        // Handle Control Hazards (Branch/Jump)
        // Control hazard has priority over load-use to prevent stuck pipeline
        if (PCSRCE) begin
            FlushD = 1'b1;
            FlushE = 1'b1;
            StallF = 1'b0;
            StallD = 1'b0;
        end
    end

endmodule
