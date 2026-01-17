module DataMemory #(
    parameter Size = 1024
    )(
    input  logic clk,
    input  logic WE,reset,
    input logic [2:0] funct3,
    input  logic [31:0] DataMemoryAddress,   
    input  logic [31:0] WD,
    output logic [31:0] DataMemoryRead
);

logic [31:0] dm[Size-1:0]; // NOTE: address not bounded yet.
// Safe for small programs; revisit when memory grows.
logic [31:0] addr;
assign addr = DataMemoryAddress[31:2];


assign DataMemoryRead=dm[DataMemoryAddress[31:2]];


logic [31:0] MaskWord1, MaskWord2;

always_comb begin

    MaskWord1 = 32'b0;
    MaskWord2 = 32'hFFFF_FFFF;


    case(funct3)
        
        3'b000: begin 
                case (DataMemoryAddress[1:0])
                    2'h0: begin MaskWord1 = {24'b0,WD[7:0]};
                          MaskWord2 = {{24{1'b1}},8'b0}; end
                    
                    2'h1: begin MaskWord1 = {16'b0,WD[7:0],8'b0};
                          MaskWord2 = {{16{1'b1}},8'b0,{8{1'b1}}}; end
                    
                    2'h2: begin MaskWord1 = {8'b0, WD[7:0],16'b0};
                          MaskWord2 = {{8{1'b1}}, 8'b0, {16{1'b1}}}; end
                    
                    2'h3: begin MaskWord1 = {WD[7:0], 24'b0};
                          MaskWord2 = {8'b0, {24{1'b1}}}; end

                    default: begin MaskWord1 = {24'b0,WD[7:0]};
                          MaskWord2 = {{24{1'b1}},8'b0};
                    end
                    endcase
                    
                 
                 end
        3'b001: begin
                case(DataMemoryAddress[1])
                    1'b0: begin MaskWord1 = {16'b0, WD[15:0]};
                          MaskWord2 = {{16{1'b1}}, 16'b0}; end
                    
                    1'b1: begin MaskWord1 = {WD[15:0], 16'b0};
                          MaskWord2 = {16'b0, {16{1'b1}}}; end
                    endcase
                
                end

        default: begin MaskWord1 = {24'b0,WD[7:0]};
                        MaskWord2 = {{24{1'b1}},8'b0}; end
        endcase
end

always_ff @(posedge clk) begin

if (WE && !reset) begin
    if (funct3 == 3'b010)
        dm[addr] <= WD;
    else
        dm[addr] <= (dm[addr] & MaskWord2) | MaskWord1;
end
end

endmodule

module Loadtype import Pkg::*;(
    input logic [31:0] DataMemoryRead,
    input logic [31:0] ALUResult,
    input logic [2:0] funct3,
    output logic [31:0] FinalDataMemoryRead
);

logic [7:0] Byte_Data;
logic [15:0] Half_Data;

always_comb begin
    Byte_Data = 8'b0;
    Half_Data = 16'b0;
    FinalDataMemoryRead = 32'b0;

    case (ALUResult[1:0])
        2'b00: Byte_Data = DataMemoryRead[7:0];
    
        2'b01: Byte_Data = DataMemoryRead[15:8];
    
        2'b10: Byte_Data = DataMemoryRead[23:16];
    
        2'b11: Byte_Data = DataMemoryRead[31:24];
    
        endcase
    
    case (ALUResult[1])
        1'b0: Half_Data = DataMemoryRead[15:0];
    
        1'b1: Half_Data = DataMemoryRead[31:16];
    
        endcase
    
    case (funct3)
        LOAD_BYTE: FinalDataMemoryRead = {{24{Byte_Data[7]}},Byte_Data};
        
        LOAD_HALF: FinalDataMemoryRead = {{16{Half_Data[15]}},Half_Data};
        
        LOAD_WORD: FinalDataMemoryRead = DataMemoryRead;
        
        LOAD_BYTE_UNSIGNED: FinalDataMemoryRead = {24'b0,Byte_Data};
        
        LOAD_HALF_UNSIGNED: FinalDataMemoryRead = {16'b0,Half_Data};

        default: begin FinalDataMemoryRead = {{24{Byte_Data[7]}},Byte_Data}; end
        endcase
     end
endmodule