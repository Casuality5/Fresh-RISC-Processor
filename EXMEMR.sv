module EXMEMRegister import Pkg::* (
    input  logic clk,
    input  logic reset,
    input  logic [31:0] ALUResult_e,
    input  logic [31:0] RD2_e,
    input  logic [31:0] PC4_e,
    input  logic [4:0]  rd_e,
    input  logic        WE_e
    input  logic        WE3_e
    input  result_mux_t ResultSelect_e,
    input  logic [1:0]  PCNext_select_e,
    output logic [31:0] ALUResult_m,
    output logic [31:0] WD_m,
    output logic [31:0] PC4_m,
    output logic [4:0]  rd_m,
    output logic        WE_m
    output logic        WE3_m,
    output result_mux_t ResultSelect_m,
    output logic [1:0]  PCNext_select_m
);

always_ff @(posedge clk) begin
    if (reset) begin
        ALUResult_m      <= 0;
        WD_m             <= 0;
        PC4_m            <= 0;
        rd_m             <= 0;;
        WE_m             <= 0;
        WE3_m            <= 0;
        ResultSelect_m   <= RESULT_ALU;
        PCNext_select_m  <= STEP_FORWARD;
    end else begin
        ALUResult_m      <= ALUResult_e;
        WD_m             <= RD2_e;
        PC4_m            <= PC4_e;
        rd_m             <= rd_e;
        WE_m             <= WE_e;
        WE3_m            <= WE3_e;
        ResultSelect_m   <= ResultSelect_e;
        PCNext_select_m  <= PCNext_select_e;
    end
end
endmodule
