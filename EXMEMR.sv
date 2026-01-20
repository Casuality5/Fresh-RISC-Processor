module EXMEMRegister import Pkg::*;(
    input  logic clk,
    input  logic reset,
    input logic [31:0] DataMemoryAddress_e,
    input logic [31:0] Target_Address_e,
    input logic [31:0] PC4_e,
    input logic [31:0] WD_e,
    input bundle_decode_t ctrl_e,
    input logic [31:0] instr_e,
    output logic [31:0] DataMemoryAddress_m,
    output logic [31:0] Target_Address_m,
    output logic [31:0] PC4_m,
    output logic [31:0] WD_m,
    output bundle_decode_t ctrl_m
);

always_ff @(posedge clk) begin
    if (reset) begin
        DataMemoryAddress_m     <= 0;
        Target_Address_m        <= 0;
        WD_m                    <= 0;
        PC4_m                   <= 0;
        ctrl_m                  <= 0;
    end else begin
        DataMemoryAddress_m      <= DataMemoryAddress_e;
        Target_Address_m         <= Target_Address_e;
        PC4_m                    <= PC4_e;
        ctrl_m                   <= ctrl_e;
    end
end
endmodule
