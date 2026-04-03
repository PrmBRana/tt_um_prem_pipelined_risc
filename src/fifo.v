module CircularBuffer #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 4
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire                  full,
    output wire                  empty
);

    localparam PTR_W = $clog2(DEPTH);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] wr_ptr, rd_ptr;
    reg [PTR_W:0]   count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    assign rd_data = mem[rd_ptr];

    // Use Async Reset for pointers/count, but NO reset for mem array (saves area)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= {PTR_W{1'b0}};
            rd_ptr <= {PTR_W{1'b0}};
            count  <= {(PTR_W+1){1'b0}};
        end else begin
            // Write Logic
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr      <= (wr_ptr == DEPTH-1) ? {PTR_W{1'b0}} : wr_ptr + 1'b1;
            end
            // Read Logic
            if (rd_en && !empty) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? {PTR_W{1'b0}} : rd_ptr + 1'b1;
            end
            // Count Logic
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: ; // Stay same
            endcase
        end
    end
endmodule
