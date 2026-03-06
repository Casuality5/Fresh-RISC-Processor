module HazardUnit(
    input logic [4:0] rsE, // rs comes from Execute stage, keep trach on Execute bundle
    input logic [4:0] rtE, //  rt comes from Execute stage, Keep track on Execute bundle
    input logic [4:0] rdM,
    input logic [4:0] rdW,
    input logic RegWriteM,
    input logic RegWriteW,
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE
);


always_comb begin

    ForwardAE = 0;
    ForwardBE = 0;

    begin : ForwardingA_logic
    if ((rsE != 0) && (rsE == rdM) && RegWriteM) begin
        ForwardAE = 2'b10;
    end
    end

    else if ((rsE != 0) &&  (rsE == rdW) && RegWriteW) begin
        ForwardAE = 2'b01;
    end
    
    begin : ForwardingB_logic
    if ((rtE != 0) && (rtE == rdM) && RegWriteM) begin
        ForwardBE = 2'b10;
    end

    else if ((rtE != 0) && (rtE == rdW) && RegWriteW) begin
        ForwardBE = 2'b01;
    end
    end
end

endmodule

