import Pkg::*;

module reg_EX_MEM (
    input  logic clk, rst,
    input  Execute_Bundle d,
    output Execute_Bundle q
);
    always_ff @(posedge clk) begin
        if (rst) begin 
        q <= '0;
        end
        else     q <= d;
    end
endmodule