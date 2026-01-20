module EXMEMRegister import Pkg::* (
    input  logic clk,
    input  logic reset,
    input logic [31:0] DataMemoryAddress_e,
    input logic [31:0] Target_Address_e,
    input logic [31:0] PC4_e,
    input logic [31:0] WD_e
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
        ALUResult_m             <= 0;
        WD_m                    <= 0;
        PC4_m                   <= 0;
        ctrl.MemW_m             <= 0;
        ctrl.ResultSelect_m     <= RESULT_ALU;
        PCNext_select_m         <= STEP_FORWARD;
    end else begin
        ALUResult_m      <= ALUResult_e;
        WD_m             <= WD_e;
        PC4_m            <= PC4_e;
        ctrl_m.MemW           <= ctrl_e.MemW
        ctrl_m.ResultSelect   <= ctrl_e.ResultSelect;
        PCNext_select_m  <= PCNext_select_e;
    end
end
endmodule
