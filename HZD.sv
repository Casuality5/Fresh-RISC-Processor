module HazardUnit import Pkg::*;(
    input logic [4:0] rsE, // rs comes from Execute stage, keep trach on Execute bundle
    input logic [4:0] rtE, //  rt comes from Execute stage, Keep track on Execute bundle
    input logic [4:0] rdE,
    input logic [4:0] rsD,
    input logic [4:0] rtD,
    input logic [4:0] rdM,
    input logic [4:0] rdW,
    input logic RegWriteM,
    input logic RegWriteW,
    input logic [6:0] OPcodeE,
    input Execute_Bundle EB,
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE,
    output logic StallF,
    output logic StallD,
    output logic FlushD,
    output logic FlushE
);

logic isLoadType;


// Muxes have to be placed in the EX stage

always_comb begin

    ForwardAE = 2'b00;
    ForwardBE = 2'b00;
    isLoadType = (OPcodeE == 7'b0000011);
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
    if (EB.Branch_taken) begin
        FlushD = 1;

    end
    end

end

endmodule

