import Pkg::*;

module reg_IF_ID (
    input  logic clk, rst, clr, enableifid,
    input  Fetch_Bundle  d,
    output Fetch_Bundle  q
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst || clr) q <= '0;
        else if (!enableifid)              q <= d;
    end
endmodule