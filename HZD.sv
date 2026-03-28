module HazardUnit import Pkg::*;(
    input logic [4:0] rdW,
    input logic RegWriteW,
    input Execute_Bundle EB,
    input Decode_Bundle DB,
    input Memory_Bundle MB,
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


assign rdE = EB.rd;
assign rdM = MB.rd;
assign RegWriteM = MB.RegW;
assign rsE = EB.instr[19:15];
assign rtE = EB.instr[24:20];
assign rsD = DB.instr[19:15];
assign rtD = DB.instr[24:20];
// Muxes have to be placed in the EX stage

always_comb begin

    ForwardAE = 2'b00;
    ForwardBE = 2'b00;
    isLoadType = (EB.instr[6:0] == 7'b0000011);
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
    if ((isLoadType) && (rdE != 0) &&((rdE == rsD) || (rdE == rtD))) begin
        StallF = 1;
        StallD = 1;
        FlushE = 1;

    end
    end


    begin: Control
    if (EB.Branch_taken || EB.Jump) begin
        FlushD = 1;
        FlushE = 1;

    end
    end

end

endmodule

