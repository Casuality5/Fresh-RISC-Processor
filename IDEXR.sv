module IDEXRegister import Pkg::*;(
    input logic clk,
    input logic reset,
    input logic [31:0] imm_d,
    input logic [31:0] Address_d,
    input bundle_decode_t ctrl_d,
    input logic [31:0] PC4_d,
    input logic [31:0] RD1_d,
    input logic [31:0] RD2_d,
    input logic [31:0] instr_d,
    output logic [31:0] imm_e,
    output logic [31:0] Address_e,
    output bundle_decode_t ctrl_e,
    output logic [31:0] PC4_e,
    output logic [31:0] RD1_e,
    output logic [31:0] RD2_e,
    output logic [31:0] instr_e
);

always_ff @(posedge clk) begin
    if (reset) begin 
        imm_e <= 0;
        Address_e <= 0;
        ctrl_e <= 0;
        PC4_e <= 0;
        RD1_e <= 0;
        RD2_e <= 0;
        instr_e <= 0;
    end else begin
        imm_e <= imm_d;
        Address_e <= Address_d;
        ctrl_e <= ctrl_d;
        PC4_e <= PC4_d;
        RD1_e <= RD1_d;
        RD2_e <= RD2_d;
        instr_e <= instr_d;
    end
end
endmodule