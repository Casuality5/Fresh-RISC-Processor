import Pkg::*;

module reg_IF_ID (
    input  logic clk, rst, clr,
    input  Fetch_Bundle  d,
    output Fetch_Bundle  q
);
    always_ff @(posedge clk) begin
        if (rst || clr) q <= '0;
        else              q <= d;
    end
endmodule