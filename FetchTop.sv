import Pkg::*;

module FetchTop(
    input logic clk, reset,
    input Execute_Bundle EB,
    output Fetch_Bundle FB
);


logic [31:0] PC4_local;
logic [31:0] PCNext_local;
logic [31:0] Address_global;




ProgramCounterMux PCM_Instance(
    .PC4(PC4_local),
    .ALUResult(EB.ALUResult),
    .Target_Address(EB.Target_Address),
    .PCNext_Select(EB.PCNext_Select),
    .PCNext(PCNext_local)
);

ProgramCounter PC_Instance(
    .clk(clk),
    .reset(reset),
    .PCNext(PCNext_local),
    .Address(Address_global)
);

PCPlus4 PC4_Instance(
    .Address(Address_global),
    .PC4(PC4_local)
);

InstructionMemory IM_Instance(
    .Address(Address_global),
    .instr(FB.instr)
);


assign FB.Address = Address_global;

endmodule