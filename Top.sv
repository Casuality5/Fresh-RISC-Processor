module Top import Pkg::*;(
    input logic clk,
    input logic rst
);

    Fetch_Bundle      if_out, id_in;
    Decode_Bundle     id_out, ex_in;
    Execute_Bundle    ex_out, mem_in;
    Memory_Bundle     mem_out, wb_in;
    
    PC_Next_Select_Case PCNext_Select;
    logic [31:0] Target_Address;
    logic [31:0] ALUResult_to_Fetch;
    logic [4:0] A3;
    logic WE3;
    logic [31:0] WD3;

        

    // 1. IF to ID Register (Instruction Fetch to Decode)
    reg_IF_ID ifid (
        .clk(clk), 
        .rst(rst), 
        .clr(1'b0),
        .d(if_out), 
        .q(id_in)
    );

    // 2. ID to EX Register (Decode to Execute)
    reg_ID_EX ide(
        .clk(clk), 
        .rst(rst),
        .d(id_out), 
        .q(ex_in)
    );

    // 3. EX to MEM Register (Execute to Memory)
    reg_EX_MEM exmem(
        .clk(clk), 
        .rst(rst),
        .d(ex_out), 
        .q(mem_in)
    );

    // 4. MEM to WB Register (Memory to Writeback)
    reg_MEM_WB memwb(
        .clk(clk), 
        .rst(rst),
        .d(mem_out), 
        .q(wb_in)
    );

    // 1. Fetch Stage
    Fetch fs(
        .clk(clk),
        .rst(rst),
        .PCNext_Select(PCNext_Select),
        .Target_Address(Target_Address),
        .FB(if_out),
        .ALUResult_to_Fetch(ALUResult_to_Fetch)
    );

    // 2. Decode Stage
    Decode ds(
        .clk(clk),
        .rst(rst),
        .FB(id_in),
        .DB(id_out),
        .A3(A3),
        .WE3(WE3),
        .WD3(WD3)
    );

    // 3. Execute Stage
    Execute es(
        .DB(ex_in),
        .EB(ex_out),
        .PCNext_Select(PCNext_Select),
        .Target_Address(Target_Address),
        .ALUResult_to_Fetch(ALUResult_to_Fetch)
    );

    // 4. Memory Stage
    Memory ms(
        .clk(clk),
        .rst(rst),
        .EB(mem_in),
        .MB(mem_out)
    );

    // 5. ResultMux (Writeback)
    ResultMux rm(
        .MB(wb_in),
        .A3(A3),
        .WE3(WE3),
        .WD3(WD3)
    );

endmodule