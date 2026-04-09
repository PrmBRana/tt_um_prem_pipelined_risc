`default_nettype none
`timescale 1ns / 1ps

// ============================================================
//  uart_bootloader
//
//  Fix: mem_addr / addr_count narrowed [7:0] → [4:0] internally.
//       mem_addr port remains 8-bit for pipeline compatibility.
//       DEPTH=32 → max address = 31 → 5 bits is sufficient.
// ============================================================
module uart_bootloader (
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,
    output reg  [7:0]  tx_data,
    output reg         tx_start,
    output reg         mem_we,
    output reg  [7:0]  mem_addr,    // 8-bit port for pipeline
    output reg  [31:0] mem_wdata,
    output reg         stall_pro
);

    localparam [7:0]  HANDSHAKE_BYTE = 8'h25;
    localparam [7:0]  ACK            = 8'h55;
    localparam [7:0]  NACK           = 8'hFF;
    localparam [31:0] SENTINEL       = 32'h00000073;

    reg handshake_done;
    reg boot_done;
    reg rx_valid_d;

    reg [31:0] buffer0, buffer1;
    reg        buffer_full0, buffer_full1;
    reg        buffer_sel;
    reg [1:0]  byte_count;
    reg [4:0]  addr_count;          // 5-bit internal counter

    wire rx_edge = rx_valid & ~rx_valid_d;

    reg [31:0] mem_wdata_reg;
    reg [4:0]  mem_addr_reg;        // 5-bit internal register
    reg        mem_we_reg;

    reg [31:0] echo_buffer;
    reg [1:0]  echo_byte_count;
    reg        echo_active;

    always @(posedge clk) begin
        if (reset) begin
            rx_valid_d      <= 1'b0;
            tx_data         <= 8'd0;
            tx_start        <= 1'b0;
            mem_we          <= 1'b0;
            mem_addr        <= 8'd0;          // assign 0 to 8-bit port
            mem_wdata       <= 32'd0;
            handshake_done  <= 1'b0;
            boot_done       <= 1'b0;
            buffer0         <= 32'd0;
            buffer1         <= 32'd0;
            buffer_full0    <= 1'b0;
            buffer_full1    <= 1'b0;
            buffer_sel      <= 1'b0;
            byte_count      <= 2'd0;
            addr_count      <= 5'd0;
            stall_pro       <= 1'b1;
            mem_wdata_reg   <= 32'd0;
            mem_addr_reg    <= 5'd0;
            mem_we_reg      <= 1'b0;
            echo_buffer     <= 32'd0;
            echo_byte_count <= 2'd0;
            echo_active     <= 1'b0;
        end else begin
            rx_valid_d <= rx_valid;
            tx_start   <= 1'b0;

            // --- Assign internal 5-bit to 8-bit port ---
            mem_we    <= mem_we_reg;
            mem_addr  <= {3'b000, mem_addr_reg};  // zero-extend to 8 bits
            mem_wdata <= mem_wdata_reg;
            stall_pro <= ~boot_done;

            // --- Handshake ---
            if (!handshake_done && rx_edge) begin
                if (rx_data == HANDSHAKE_BYTE) begin
                    tx_data        <= ACK;
                    tx_start       <= 1'b1;
                    handshake_done <= 1'b1;
                end else begin
                    tx_data  <= NACK;
                    tx_start <= 1'b1;
                end
            end

            // --- Data reception ---
            else if (handshake_done && rx_edge && !boot_done) begin
                if (buffer_sel == 1'b0) begin
                    case (byte_count)
                        2'd0: buffer0[7:0]   <= rx_data;
                        2'd1: buffer0[15:8]  <= rx_data;
                        2'd2: buffer0[23:16] <= rx_data;
                        2'd3: begin
                            buffer0[31:24] <= rx_data;
                            buffer_full0   <= 1'b1;
                        end
                    endcase
                end else begin
                    case (byte_count)
                        2'd0: buffer1[7:0]   <= rx_data;
                        2'd1: buffer1[15:8]  <= rx_data;
                        2'd2: buffer1[23:16] <= rx_data;
                        2'd3: begin
                            buffer1[31:24] <= rx_data;
                            buffer_full1   <= 1'b1;
                        end
                    endcase
                end

                if (byte_count == 2'd3) begin
                    byte_count <= 2'd0;
                    buffer_sel <= ~buffer_sel;
                end else begin
                    byte_count <= byte_count + 1'b1;
                end
            end

            // --- Memory write pipeline ---
            if (buffer_full0) begin
                mem_wdata_reg   <= buffer0;
                mem_addr_reg    <= addr_count;
                mem_we_reg      <= 1'b1;
                addr_count      <= addr_count + 1'b1;
                buffer_full0    <= 1'b0;
                echo_buffer     <= buffer0;
                echo_byte_count <= 2'd0;
                echo_active     <= 1'b1;
                if (buffer0 == SENTINEL) boot_done <= 1'b1;
            end else if (buffer_full1) begin
                mem_wdata_reg   <= buffer1;
                mem_addr_reg    <= addr_count;
                mem_we_reg      <= 1'b1;
                addr_count      <= addr_count + 1'b1;
                buffer_full1    <= 1'b0;
                echo_buffer     <= buffer1;
                echo_byte_count <= 2'd0;
                echo_active     <= 1'b1;
                if (buffer1 == SENTINEL) boot_done <= 1'b1;
            end else begin
                mem_we_reg <= 1'b0;
            end

            // --- UART echo ---
            if (echo_active && !tx_start) begin
                tx_data  <= echo_buffer[8*echo_byte_count +: 8];
                tx_start <= 1'b1;
                if (echo_byte_count == 2'd3)
                    echo_active <= 1'b0;
                else
                    echo_byte_count <= echo_byte_count + 1'b1;
            end
        end
    end
endmodule



