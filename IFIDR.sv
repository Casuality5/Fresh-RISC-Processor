module reg_IF_ID (
    input  logic clk, rst, clear,
    input  Fetch_Bundle  in,
    output Fetch_Bundle  out
);
    always_ff @(posedge clk) begin
        if (rst || clear) out <= '0;
        else              out <= in;
    end
endmodule