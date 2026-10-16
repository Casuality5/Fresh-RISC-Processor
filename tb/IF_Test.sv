`timescale 1ps/1ps

module IF_Test import Pkg::*;();

logic clk;
logic reset;
logic [31:0] PC4;
logic [31:0] ALUResult;
logic [31:0] Target_Address;
pc_next_select_t PCNext_select;
logic [31:0] PCNext;
logic [31:0] Address;
logic [31:0] instr;

ProgramCounterMux pcm(
    .PC4(PC4),
    .ALUResult(ALUResult),
    .Target_Address(Target_Address),
    .PCNext_select(PCNext_select),
    .PCNext(PCNext)
);

ProgramCounter pc(
    .clk(clk),
    .reset(reset),
    .PCNext(PCNext),
    .Address(Address)
);

InstructionMemory im(
    .Address(Address),
    .instr(instr)
);

always #5 clk = ~clk;

initial begin 
    clk = 0;
    reset = 1;
    ALUResult = 32'h0000_0100;
    Target_Address = 32'h0000_0200;
    PCNext_select = STEP_FORWARD;

    #12;
    reset = 0;

    repeat(3) begin 
        PCNext_select = STEP_FORWARD;
        @(posedge clk);
    end

    PCNext_select = JUMP_TO_CALCULATED_REGISTER;
    @(posedge clk);


    PCNext_select = STEP_FORWARD;
    repeat(2) @(posedge clk);

    PCNext_select = JUMP_TO_LABEL;
    @(posedge clk);

    $finish;
end

initial begin 
    $display("Time\tPC\t\tPC4\t\tPCNext\t\tInstr\t\tSelect");
    $monitor("%0t\t%h\t%h\t%h\t%h\t%0d",$time, Address, PC4, PCNext, instr, PCNext_select);
end
endmodule



