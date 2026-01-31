import Pkg::*;

module reg_ID_EX (
    input  logic clk, rst,
    input  Decode_Bundle d,
    output Decode_Bundle q
);
    always_ff @(posedge clk) begin
        if (rst) q <= '0;
        else     q <= d;
    end
endmodule