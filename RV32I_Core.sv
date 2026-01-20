module RV32I_Core import Pkg::*;(
    input logic clk,
    input logic reset
);

// Wirings
logic [31:0] Address_f;
logic [31:0] PC_f;
logic [31:0] PC4_f;
logic [31:0] instr_f;
logic [31:0] PCNext_f;

pc_next_select_t PCNext_select_f;

logic [31:0] instr_d;
logic [31:0] imm_d;
logic [31:0] RD1_d;
logic [31:0] RD2_d;
logic [31:0] Address_d;
logic [31:0] PC4_d;

ctrl_t  ctrl_d;        // assuming structured control bundle
logic [1:0] ALUOp_d;
logic [3:0] ALUControl_d;

logic [31:0] instr_e;
logic [31:0] imm_e;
logic [31:0] Address_e;
logic [31:0] PC4_e;
logic [31:0] RD1_e;
logic [31:0] RD2_e;

logic [31:0] SrcA_e;
logic [31:0] SrcB_e;
logic [31:0] ALUResult_e;
logic [31:0] Target_Address_e;

logic [3:0]  ALUControl_e;
logic        SrcASelect_e;
logic        SrcBSelect_e;

logic        Zero_e;
logic        SLTFlagSigned_e;
logic        SLTFlagUnsigned_e;

logic        Branch_taken_e;
pc_next_select_t PCNext_select_e;

ctrl_t ctrl_e;

logic [31:0] instr_m;
logic [31:0] ALUResult_m;
logic [31:0] DataMemoryAddress_m;
logic [31:0] WD_m;
logic [31:0] DataMemoryRead_m;
logic [31:0] FinalDataMemoryRead_m;
logic [31:0] PC4_m;

pc_next_select_t PCNext_select_m;
ctrl_t ctrl_m;

logic [31:0] ALUResult_w;
logic [31:0] FinalDataMemoryRead_w;
logic [31:0] PC4_w;
logic [31:0] Result_w;

result_select_t ResultSelect_w;
ctrl_t ctrl_w;


// IF Stage
ProgramCounterMux pcmux(
    .PC4(PC4_f),
    .ALUResult(ALUResult_w),
    .Target_Address(Target_Address_e),
    .PCNext_select(PCNext_select_f), // Keep check
    .PCNext(PCNext_f)
);

ProgramCounter pc(
    .clk(clk),
    .reset(reset),
    .PCNext(PCNext_f),
    .Address(Address_f)
);

PCPlus4 pls4(
    .Address(Address_f),
    .PC4(PC4_f)
);

InstructionMemory im(
    .Address(Address_f),
    .instr(instr_f)
);

IFIDRegister ifid(
    .clk(clk),
    .reset(reset),
    .instr_f(instr_f),
    .Address_f(Address_f),
    .PC4_f(PC4_f),
    .instr_d(instr_d),
    .Address_d(Address_d),
    .PC4_d(PC4_d)
);

// ID Stage

Immediate_Generator img(
    .instr(instr_d),
    .imm(imm_d)
);

Decoder dec(
    .Opcode(instr_d[6:0]),
    .ctrl(ctrl_d)
);

ALU_Decoder adec(
    .ALUOp(ALUOp_d),
    .funct3(instr_d[14:12]),
    .funct7(instr_d[31:25]),
    .ALUControl(ALUControl_d)
);

RegisterFile rf(
    .clk(clk),
    .reset(reset),
    .WE3(ctrl.RegW),
    .A1(instr_d[19:15]), .A2(instr_d[24:20]), .A3(instr_d[11:7]),
    .WD3(Result_w), .RD1(RD1_d), .RD2(RD2_d) 
);

IDEXRegister idex(
    .clk(clk),
    .reset(reset),
    .imm_d(imm_d),
    .Address_d(Address_d),
    .ctrl_d(ctrl_d),
    .PC4_d(PC4_d),
    .RD1_d(RD1_d), RD2_d(RD2_d),
    .instr_d(instr_d),
    .imm_e(imm_e),
    .Address_e(Address_e),
    .ctrl_e(ctrl_e),
    .PC4_e(PC4_e),
    .RD1_e(RD1_e), RD2_e(RD2_e),
    .instr_e(instr_e)
);

// EX Stage

ALU alu(
    .SrcA(SrcA_e), .SrcB(SrcB_e),
    .ALUControl(ALUControl_e),
    .funct3(instr_e[14:12]),
    .ALUResult(ALUResult_e),
    .Zero(Zero_e),
    .SLTFlagSigned(SLTFlagSigned_e),
    .SLTFlagUnsigned(SLTFlagUnsigned_e)
);

PCTarget pct(
    .Address(Address_e),
    .imm(imm_e),
    .Target_Address(Target_Address_e)
);

SrcBMux srcb(
    .RD2(RD2_e),
    .imm(imm_e),
    .SrcBSelect(SrcBSelect_e),
    .SrcB(SrcB_e)
);

SrcAMux srca(
    .RD1(RD1_e),
    .Address(Address_e),
    .SrcASelect(SrcASelect_e),
    .SrcA(SrcA_e)
);

Branch_Producer bp(
    .ctrl(ctrl_e),
    .funct3(instr_e[14:12]),
    .Zero(Zero_e),
    .SLTFlagSigned(SLTFlagSigned_e),
    .SLTFlagUnsigned(SLTFlagUnsigned_e),
    .Branch_taken(Branch_taken_e),
    .PCNext_select(PCNext_select_e)
);

EXMEMRegister exmem(
    .clk(clk),
    .reset(reset),
    .DataMemoryAddress_e(DataMemoryAddress_e),
    .WD_e(WD_e)
    .PCNext_select_e(PCNext_select_e),
    .ctrl_e(ctrl_e),
    .DataMemoryAddress_m(DataMemoryAddress_m),
    .WD_m(WD_m),
    .PC4_m(PC4_m),
    .PCNext_select_m(PCNext_select_m),
    .ctrl_m(ctrl_m)
);
// Mem Stage

DataMemory dm(
    .clk(clk),
    .reset(reset),
    .WE(ctrl_m.MemW),
    .funct3(instr_m[14:12]),
    .DataMemoryAddress(DataMemoryAddress_m),
    .WD(WD_m),
    .DataMemoryRead(DataMemoryRead_m)
);

Loadtype ld(
    .DataMemoryRead(DataMemoryRead_m),
    .ALUResult(DataMemoryAddress_m),
    .funct3(instr_m[14:12]),
    .FinalDataMemoryRead(FinalDataMemoryRead_m)
);

MEMWBRegister memwb(
    .clk(clk),
    .reset(reset),
    .ALUResult_m(ALUResult_m),
    .FinalDataMemoryRead_m(FinalDataMemoryRead_m),
    .PC4_m(PC4_m),
    .ctrl_m(ctrl_m),
    .ALUResult_w(ALUResult_w),
    .PC4_w(PC4_w),
    .ctrl_w(ctrl_w)
);

// WB Stage

ResultMux rm(
    .ALUResult(ALUResult_w),
    .FinalDataMemoryRead(FinalDataMemoryRead_w),
    .ResultSelect(ResultSelect_w),
    .Result(Result_w)
);

endmodule