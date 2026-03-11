import Pkg::*;

module reg_ID_EX (
    input  logic clk, rst, clre,
    input  Decode_Bundle d,
    output Decode_Bundle q
);
    always_ff @(posedge clk) begin
        if (rst || clre) q <= '0;
        else     q <= d;
    end
endmodule