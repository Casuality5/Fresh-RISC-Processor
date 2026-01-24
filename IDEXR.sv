module reg_ID_EX (
    input  logic clk, rst,
    input  Decode_Bundle in,
    output Decode_Bundle out
);
    always_ff @(posedge clk) begin
        if (rst) out <= '0;
        else     out <= in;
    end
endmodule