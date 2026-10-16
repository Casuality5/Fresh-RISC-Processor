`timescale 1ns / 1ps

import Pkg::*;

module Top #(
    parameter Size = 4096
)(
    input  logic clk,
    input  logic rst,
    
    input  logic [31:0] AWADDR,
    input  logic [7:0]  AWLEN,
    input  logic [2:0]  AWSIZE,
    input  logic [1:0]  AWBURST,
    input  logic        AWVALID,
    output logic        AWREADY,

    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WVALID,
    input  logic        WLAST,
    output logic        WREADY,

    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,

    input  logic [31:0] ARADDR,
    input  logic [7:0]  ARLEN,
    input  logic [2:0]  ARSIZE,
    input  logic [1:0]  ARBURST,
    input  logic        ARVALID,
    output logic        ARREADY,

    output logic [31:0] RDATA,
    output logic        RVALID,
    output logic        RLAST,
    output logic [1:0]  RRESP,
    input  logic        RREADY,
    
    output logic [31:0] SOURCE_OUT,
    output logic [31:0] DESTINATION_OUT,
    output logic [31:0] CONTROL_OUT

);

    Fetch_Bundle   if_out;
    Fetch_Bundle   id_in; 
    Decode_Bundle  id_out;
    Decode_Bundle  ex_in;
    Execute_Bundle ex_out;
    Execute_Bundle mem_in;
    Memory_Bundle  mem_out;
    Memory_Bundle  wb_in;

    logic [31:0] WD3;
    logic [4:0]  A3;
    logic        WE3;

    logic enableif;    // StallF
    logic enableifid;  // StallD
    logic clr;         // FlushD
    logic clre;        // FlushE
    logic [1:0] ForwardAE;
    logic [1:0] ForwardBE;

    PC_Next_Select_Case PCNext_Select;
    logic [31:0] Target_Address;
    logic [31:0] ALUResult_to_Fetch;

    Fetch #(
        .Size(Size)
    ) IF_Stage (
        .clk                 (clk),
        .rst                 (rst),
        .enableif            (enableif),
        .PCNext_Select       (PCNext_Select),
        .Target_Address      (Target_Address),
        .ALUResult_to_Fetch  (ALUResult_to_Fetch),
        .FB                  (if_out)
    );

    reg_IF_ID ifid (
        .clk        (clk),
        .rst        (rst),
        .clr        (clr),
        .enableifid (enableifid),
        .d          (if_out),
        .q          (id_in)
    );

    Decode ID_Stage (
        .clk (clk),
        .rst (rst),
        .FB  (id_in),
        .A3  (A3),
        .WE3 (WE3),
        .WD3 (WD3),
        .DB  (id_out)
    );

    reg_ID_EX idex (
        .clk  (clk),
        .rst  (rst),
        .clre (clre),
        .d    (id_out),
        .q    (ex_in)
    );

    Execute EX_Stage (
        .DB                 (ex_in),
        .MB                 (mem_out),
        .MB_ALUResult        (mem_out.ALUResult),
        .WD3                (WD3),
        .ForwardAE          (ForwardAE),
        .ForwardBE          (ForwardBE),
        .EB                 (ex_out),
        .PCNext_Select      (PCNext_Select),
        .Target_Address     (Target_Address),
        .ALUResult_to_Fetch (ALUResult_to_Fetch)
    );

    reg_EX_MEM exmem (
        .clk (clk),
        .rst (rst),
        .d   (ex_out),
        .q   (mem_in)
    );

    Memory #(
        .Size(Size)
    ) DM_Stage (
        .clk    (clk),
        .rst    (rst),
        .EB     (mem_in),
        .MB     (mem_out),
        
        .AWADDR     (AWADDR),
        .AWLEN      (AWLEN),
        .AWSIZE     (AWSIZE),
        .AWBURST    (AWBURST),
        .AWVALID    (AWVALID),
        .AWREADY    (AWREADY),
        .WDATA      (WDATA),
        .WSTRB      (WSTRB),
        .WVALID     (WVALID),
        .WLAST      (WLAST),
        .WREADY     (WREADY),
        .BRESP      (BRESP),
        .BVALID     (BVALID),
        .BREADY     (BREADY),
        .ARADDR     (ARADDR),
        .ARLEN      (ARLEN),
        .ARSIZE     (ARSIZE),
        .ARBURST    (ARBURST),
        .ARVALID    (ARVALID),
        .ARREADY    (ARREADY),
        .RDATA      (RDATA),
        .RVALID     (RVALID),
        .RLAST      (RLAST),
        .RRESP      (RRESP),
        .RREADY     (RREADY),
        
        .Source_out (SOURCE_OUT),
        .Destination_out (DESTINATION_OUT),
        .Control_out(CONTROL_OUT)
    );

    reg_MEM_WB memwb (
        .clk (clk),
        .rst (rst),
        .d   (mem_out),
        .q   (wb_in)
    );

    ResultMux WB_Stage (
        .MB  (wb_in),
        .WE3 (WE3),
        .A3  (A3),
        .WD3 (WD3)
    );

    HazardUnit Hazard_Ctrl (
        .rdW            (A3),
        .RegWriteW      (WE3),
        .EB_instr       (ex_in.instr),
        .EB_rd          (ex_in.rd),
        .EB_branch_taken(ex_out.Branch_taken),
        .EB_jump        (ex_out.Jump),
        .DB_instr       (id_in.instr),
        .MB_rd          (mem_in.rd),
        .MB_RegW        (mem_in.RegW),
        .ForwardAE      (ForwardAE),
        .ForwardBE      (ForwardBE),
        .StallF         (enableif),
        .StallD         (enableifid),
        .FlushD         (clr),
        .FlushE         (clre)
    );

endmodule