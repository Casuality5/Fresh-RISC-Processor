module RV32I_Core import Pkg::*;(
    input logic clk,
    input logic reset
);

// --- Pipeline Bundle Wires ---
    // _out = raw output of the stage (combinational)
    // _reg = output of the pipeline register (delayed 1 cycle)

    Fetch_Bundle      if_out, id_in;   // if_out -> Reg -> id_in
    Decode_Bundle     id_out, ex_in;   // id_out -> Reg -> ex_in
    Execute_Bundle    ex_out, mem_in;  // ex_out -> Reg -> mem_in
    Memory_Bundle     mem_out, wb_in;  // mem_out -> Reg -> wb_in
    WriteBack_Bundle  wb_out;          // Loops back to Decode

    // 1. IF to ID Register (Instruction Fetch to Decode)
    Pipeline_Reg #(.T(Fetch_Bundle)) IF_ID_REG (
        .clk(clk), 
        .rst(rst), 
        .en(1'b1), 
        .clr(1'b0),
        .d(if_out), 
        .q(id_in)
    );

    // 2. ID to EX Register (Decode to Execute)
    Pipeline_Reg #(.T(Decode_Bundle)) ID_EX_REG (
        .clk(clk), 
        .rst(rst), 
        .en(1'b1), 
        .clr(1'b0),
        .d(id_out), 
        .q(ex_in)
    );

    // 3. EX to MEM Register (Execute to Memory)
    Pipeline_Reg #(.T(Execute_Bundle)) EX_MEM_REG (
        .clk(clk), 
        .rst(rst), 
        .en(1'b1), 
        .clr(1'b0),
        .d(ex_out), 
        .q(mem_in)
    );

    // 4. MEM to WB Register (Memory to Writeback)
    Pipeline_Reg #(.T(Memory_Bundle)) MEM_WB_REG (
        .clk(clk), 
        .rst(rst), 
        .en(1'b1), 
        .clr(1'b0),
        .d(mem_out), 
        .q(wb_in)
    );

    // 1. Fetch Stage
    Fetch fs(
        .clk(clk),
        .rst(reset),
        .EB(mem_in),   // Branch/Jump decisions from EX/MEM register
        .FB(if_out)    // Raw instruction out
    );

    // 2. Decode Stage
    Decode ds(
        .clk(clk),
        .rst(reset),
        .FB(id_in),    // Buffered instruction from IF/ID
        .WB(wb_out),   // Looped back from ResultMux
        .DB(id_out)    // Raw decoded signals out
    );

    // 3. Execute Stage
    Execute es(
        .DB(ex_in),    // Buffered signals from ID/EX
        .EB(ex_out)    // Raw ALU results out
    );

    // 4. Memory Stage
    Memory ms(
        .clk(clk),
        .rst(reset),
        .EB(mem_in),   // Buffered results from EX/MEM
        .MB(mem_out)   // Raw memory data out
    );

    // 5. ResultMux (Writeback)
    ResultMux rm(
        .MB(wb_in),    // Buffered data from MEM/WB
        .WB(wb_out)    // Result looped back to Decode
    );
endmodule