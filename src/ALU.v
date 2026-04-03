`default_nettype none
`timescale 1ns / 1ps

module ALU (
    input  wire [31:0] ScrA,
    input  wire [31:0] ScrB,
    input  wire [3:0]  ALUControl,
    input  wire [1:0]  ALUType,
    output reg  [31:0] ALUResult,
    output reg         Zero
);

    // Pre-calculate the Adder/Subtractor (fastest way for synthesis to map to hardware)
    wire [31:0] sum  = ScrA + ScrB;
    wire [31:0] diff = ScrA - ScrB;

    always @(*) begin
        // Default values to prevent latches
        ALUResult = 32'd0;
        Zero      = 1'b0;

        case (ALUType)
            // ── S-type (Store) & J-type (Jump) ─────────────────
            // These only need the Adder. We use the pre-calculated 'sum'.
            2'b01, 2'b11: begin
                ALUResult = sum;
            end

            // ── B-type (Branch Comparison) ─────────────────────
            2'b10: begin
                case (ALUControl)
                    4'b0000: Zero = (ScrA == ScrB);                   // BEQ
                    4'b0001: Zero = (ScrA != ScrB);                   // BNE
                    4'b0010: Zero = ($signed(ScrA) <  $signed(ScrB)); // BLT
                    4'b0011: Zero = ($signed(ScrA) >= $signed(ScrB)); // BGE
                    4'b0100: Zero = (ScrA <  ScrB);                   // BLTU
                    4'b0101: Zero = (ScrA >= ScrB);                   // BGEU
                    default: Zero = 1'b0;
                endcase
            end

            // ── R/I-type (Arithmetic and Logic) ────────────────
            2'b00: begin
                case (ALUControl)
                    4'b0010: ALUResult = sum;                         // ADD / ADDI
                    4'b0011: ALUResult = diff;                        // SUB
                    4'b0000: ALUResult = ScrA & ScrB;                 // AND
                    4'b0001: ALUResult = ScrA | ScrB;                 // OR
                    4'b0100: ALUResult = ScrA ^ ScrB;                 // XOR
                    4'b1000: ALUResult = ($signed(ScrA) < $signed(ScrB)) ? 32'd1 : 32'd0; // SLT
                    4'b1001: ALUResult = (ScrA < ScrB) ? 32'd1 : 32'd0;                // SLTU
                    // Shifters are usually the slowest part of an ALU
                    4'b0101: ALUResult = ScrA << ScrB[4:0];           // SLL
                    4'b0110: ALUResult = ScrA >> ScrB[4:0];           // SRL
                    4'b0111: ALUResult = $signed(ScrA) >>> ScrB[4:0]; // SRA
                    default: ALUResult = 32'd0;
                endcase
            end

            default: begin
                ALUResult = 32'd0;
                Zero      = 1'b0;
            end
        endcase
    end

endmodule
