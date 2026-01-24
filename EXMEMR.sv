module reg_EX_MEM (
    input  logic clk, rst,
    input  Execute_Bundle in,
    output Execute_Bundle out
);
    always_ff @(posedge clk) begin
        if (rst) out <= '0;
        else     out <= in;
    end
endmodule