module HazardUnit import Pkg::*;(
    input logic [4:0] rdW,
    input logic RegWriteW,
    input logic [31:0] EB_instr,
    input logic [4:0] EB_rd,
    input logic EB_branch_taken,
    input logic EB_jump,
    input logic [31:0] DB_instr,
    input logic [4:0] MB_rd,
    input logic MB_RegW,
    
//    input Execute_Bundle EB,
//    input Decode_Bundle DB,
//    input Memory_Bundle MB,
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE,
    output logic StallF,
    output logic StallD,
    output logic FlushD,
    output logic FlushE
);

logic isLoadType;
logic [4:0] rsE;
logic [4:0] rtE;
logic [4:0] rsD;
logic [4:0] rtD;
logic [4:0] rdE;
logic [4:0] rdM;
logic RegWriteM;


assign rdE = EB_rd; // this
assign rdM = MB_rd; // this
assign RegWriteM = MB_RegW; // this
    assign rsE = EB_instr[19:15]; // this
    assign rtE = EB_instr[24:20]; // this
    assign rsD = DB_instr[19:15]; // this
    assign rtD = DB_instr[24:20]; // this

    logic rs1_valid;
    logic rs2_valid;
    
    assign rs1_valid = (DB_instr[6:0] != 7'b0110111) && // LUI
                       (DB_instr[6:0] != 7'b0010111) && // AUIPC
                       (DB_instr[6:0] != 7'b1101111);   // JAL
                       
    assign rs2_valid = (DB_instr[6:0] == 7'b0110011) || // R-Type
                       (DB_instr[6:0] == 7'b1100011) || // Branch
                       (DB_instr[6:0] == 7'b0100011);   // Store

always_comb begin

    ForwardAE = 2'b00;
    ForwardBE = 2'b00;
    isLoadType = (EB_instr[6:0] == 7'b0000011); // this 
    StallF     = 0;
    StallD     = 0;
    FlushD     = 0;
    FlushE     = 0;


    begin : ForwardingA_logic
    if ((rsE != 0) && (rsE == rdM) && RegWriteM) begin
        ForwardAE = 2'b10;
    end

    else if ((rsE != 0) &&  (rsE == rdW) && RegWriteW) begin
        ForwardAE = 2'b01;
    end
    end
    
    begin : ForwardingB_logic
    if ((rtE != 0) && (rtE == rdM) && RegWriteM) begin
        ForwardBE = 2'b10;
    end

    else if ((rtE != 0) && (rtE == rdW) && RegWriteW) begin
        ForwardBE = 2'b01;
    end
    end


    begin: Stalling
    if ((isLoadType) && (rdE != 0) && (((rdE == rsD) && rs1_valid) || ((rdE == rtD) && rs2_valid))) begin
        StallF = 1;
        StallD = 1;
        FlushE = 1;
    end
    end

    begin: Control
    if (EB_branch_taken || EB_jump) begin // this 
        FlushD = 1;
        FlushE = 1;

    end
    end

end

endmodule

