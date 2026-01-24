module reg_MEM_WB (
    input  logic           clk, rst,
    input  Memory_Bundle   in,   // Data coming from Memory_Stage
    output Memory_Bundle   out   // Data going to ResultMux (Writeback)
);

    always_ff @(posedge clk) begin
        if (rst) begin
            out <= '0; // Clear the trunk on reset
        end else begin
            out <= in;  // Hand off the trunk to the final stage
        end
    end

endmodule