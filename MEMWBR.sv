import Pkg::*;

module reg_MEM_WB (
    input  logic           clk, rst,
    input  Memory_Bundle   d,
    output Memory_Bundle   q
);

    always_ff @(posedge clk) begin
        if (rst) begin
            q <= '0; 
        end else begin
            q <= d;
        end
    end

endmodule