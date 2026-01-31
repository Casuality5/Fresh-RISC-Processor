import Pkg::*;

module Memory #(
    parameter Size = 1024
    )(
    input Execute_Bundle EB,
    output Memory_Bundle MB,
    input  logic clk,
    input  logic rst
);

logic [31:0] DataMemoryRead;
logic [31:0] dm[Size-1:0];
logic [31:0] addr;
assign addr = MB.ALUResult[31:2];
assign DataMemoryRead=dm[MB.ALUResult[31:2]];
logic [31:0] MaskWord1, MaskWord2;
logic [7:0] Byte_Data;
logic [15:0] Half_Data;
initial begin
        for (int i = 0; i < Size; i++) begin
            dm[i] = 32'b0;
        end
    end
always_comb begin
    MB.WE = EB.WE;
    MB.instr = EB.instr;
    MB.WD = EB.RD2;
    MB.RegW = EB.RegW;
    MB.PC4 = EB.PC4;
    MB.rd = EB.rd;
    MB.ALUResult = EB.ALUResult;
    MB.ResultSelect = EB.ResultSelect;
    MaskWord1 = 32'b0;
    MaskWord2 = 32'hFFFF_FFFF;
    Byte_Data = 8'b0;
    Half_Data = 16'b0;
    MB.FinalDataMemoryRead = 32'b0;

                                                                                                    
    case(MB.instr[14:12])
        
        3'b000: begin 
                case (MB.ALUResult[1:0])
                    2'h0: begin MaskWord1 = {24'b0,MB.WD[7:0]};
                          MaskWord2 = {{24{1'b1}},8'b0}; end
                    
                    2'h1: begin MaskWord1 = {16'b0,MB.WD[7:0],8'b0};
                          MaskWord2 = {{16{1'b1}},8'b0,{8{1'b1}}}; end
                    
                    2'h2: begin MaskWord1 = {8'b0, MB.WD[7:0],16'b0};
                          MaskWord2 = {{8{1'b1}}, 8'b0, {16{1'b1}}}; end
                    
                    2'h3: begin MaskWord1 = {MB.WD[7:0], 24'b0};
                          MaskWord2 = {8'b0, {24{1'b1}}}; end

                    default: begin MaskWord1 = {24'b0,MB.WD[7:0]};
                          MaskWord2 = {{24{1'b1}},8'b0};
                    end
                    endcase
                    
                 
                 end
        3'b001: begin
                case(MB.ALUResult[1])
                    1'b0: begin MaskWord1 = {16'b0, MB.WD[15:0]};
                          MaskWord2 = {{16{1'b1}}, 16'b0}; end
                    
                    1'b1: begin MaskWord1 = {MB.WD[15:0], 16'b0};
                          MaskWord2 = {16'b0, {16{1'b1}}}; end
                    endcase
                
                end
        3'b010: begin // SW
             MaskWord1 = MB.WD;
             MaskWord2 = 32'h0000_0000;
                 end


        default: begin MaskWord1 = {24'b0,MB.WD[7:0]};
                        MaskWord2 = {{24{1'b1}},8'b0}; end
        endcase

        case (MB.ALUResult[1:0])
        2'b00: Byte_Data = DataMemoryRead[7:0];
    
        2'b01: Byte_Data = DataMemoryRead[15:8];
    
        2'b10: Byte_Data = DataMemoryRead[23:16];
    
        2'b11: Byte_Data = DataMemoryRead[31:24];
    
        endcase
    
    case (MB.ALUResult[1])
        1'b0: Half_Data = DataMemoryRead[15:0];
    
        1'b1: Half_Data = DataMemoryRead[31:16];
    
        endcase
    
    case (MB.instr[14:12])
        LOAD_BYTE: MB.FinalDataMemoryRead = {{24{Byte_Data[7]}},Byte_Data};
        
        LOAD_HALF: MB.FinalDataMemoryRead = {{16{Half_Data[15]}},Half_Data};
        
        LOAD_WORD: MB.FinalDataMemoryRead = DataMemoryRead;
        
        LOAD_BYTE_UNSIGNED: MB.FinalDataMemoryRead = {24'b0,Byte_Data};
        
        LOAD_HALF_UNSIGNED: MB.FinalDataMemoryRead = {16'b0,Half_Data};

        default: begin MB.FinalDataMemoryRead = {{24{Byte_Data[7]}},Byte_Data}; end
        endcase
end

always_ff @(posedge clk) begin
  if (!rst && MB.WE) begin
    dm[addr] <= MB.WD;
  end
end



endmodule
