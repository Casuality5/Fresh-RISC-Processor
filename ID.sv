import Pkg::*;


module Decode(
    input clk,
    input rst,
    input Fetch_Bundle FB,
    input WriteBack_Bundle WB,
    output Decode_Bundle DB
);
    localparam Rt =      7'b0110011;
    localparam It =      7'b0000011;
    localparam IALUt =   7'b0010011; // I-Type
    localparam St =      7'b0100011;
    localparam Bt =      7'b1100011;
    localparam AUIPCt =  7'b0010111; // U-Type
    localparam LUIt =    7'b0110111; // U-Type
    localparam JALt =    7'b1101111; // J-Type
    localparam JALRt =   7'b1100111; // I-Type
    
    localparam ADD  = 4'h0;
    localparam SUB  = 4'h1;
    localparam AND  = 4'h2;
    localparam OR   = 4'h3;
    localparam XOR  = 4'h4;
    localparam SLL  = 4'h5;
    localparam SRL  = 4'h6;
    localparam SRA  = 4'h7;
    localparam SLT  = 4'h8;
    localparam SLTU = 4'h9;


logic [31:0] rf[31:0];

always_comb begin

    DB = '0;
    DB.instr = FB.instr;
    DB.A1    = FB.instr[19:15];
    DB.A2    = FB.instr[24:20];
    DB.A3    = FB.instr[11:7];
    DB.RD1 = ((DB.A1 != 0) ? rf[DB.A1] : 32'b0);
    DB.RD2 = ((DB.A2 != 0) ? rf[DB.A2] : 32'b0);

    case (FB.instr[6:0])
        Rt:                      DB.imm = 32'b0;

        It, JALRt, IALUt:          DB.imm = {{20{FB.instr[31]}},FB.instr[31:20]};

        St:                      DB.imm = {{20{FB.instr[31]}},FB.instr[31:25],FB.instr[11:7]};

        Bt:                      DB.imm = {{20{FB.instr[31]}},FB.instr[7],FB.instr[30:25],FB.instr[11:8],1'b0};

        AUIPCt, LUIt:             DB.imm = {FB.instr[31:12],12'b0};
        
        JALt:                    DB.imm = {{12{FB.instr[31]}},FB.instr[19:12],FB.instr[20],FB.instr[30:21],1'b0};

        default:                DB.imm = 32'b0;
    endcase

    

    case (FB.instr[6:0]) 
        Rt: begin // R- Type
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=0;      
            DB.ALUSrcA=0;      
            DB.ALUOp=CHECK_FUNCT_CODE;     
            DB.ImmSrc=R;
            DB.ResultSelect=RESULT_ALU;
        end

        IALUt: begin // I- Type ALU
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=I_TYPE_MATH;     
            DB.ImmSrc=I;
            DB.ResultSelect=RESULT_ALU;
        end

        It: begin // Load
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_ADD;     
            DB.ImmSrc=LOAD;
            DB.ResultSelect= RESULT_MEM;
        end

        St: begin // Store
            DB.RegW=0;     
            DB.MemW=1;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_ADD;     
            DB.ImmSrc=STORE;
            DB.ResultSelect=RESULT_ALU;
        end

        Bt: begin // Branch- Type
            DB.RegW=0;     
            DB.MemW=0;     
            DB.Branch=1;       
            DB.Jump=0;     
            DB.ALUSrcB=0;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_SUB;                                      
            DB.ImmSrc=B;
            DB.ResultSelect=RESULT_ALU;
            
        end

        JALt: begin // JAL
            DB.RegW=0;
            DB.MemW=0;
            DB.Branch=0;
            DB.Jump=1;
            DB.ALUSrcB=0;
            DB.ALUSrcA=0;
            DB.ALUOp=FORCE_ADD;
            DB.ImmSrc=JAL;
            DB.ResultSelect=RESULT_PC;
        end

        JALRt: begin // JALR
            DB.RegW=0;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=1;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_ADD;         
            DB.ImmSrc=JALR;
            DB.ResultSelect=RESULT_PC;
        end

        LUIt: begin // LUI
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_ADD;      
            DB.ImmSrc=LUI;
            DB.ResultSelect=RESULT_ALU;
        end

        AUIPCt: begin // AUIPC
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=1;      
            DB.ALUOp=FORCE_ADD;      
            DB.ImmSrc=AUIPC;
            DB.ResultSelect=RESULT_ALU;
        end

    endcase



    case (DB.ALUOp)
        FORCE_ADD: begin 
            DB.ALUControl = ADD;
        end

        FORCE_SUB: begin 
            DB.ALUControl = SUB;
        end

        CHECK_FUNCT_CODE: begin
            case (FB.instr[14:12])
                3'b000:     DB.ALUControl = (FB.instr[30] ? SUB : ADD);
                3'b001:     DB.ALUControl = SLL;
                3'b010:     DB.ALUControl = SLT;
                3'b011:     DB.ALUControl = SLTU;
                3'b100:     DB.ALUControl = XOR;
                3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                3'b110:     DB.ALUControl = OR;
                3'b111:     DB.ALUControl = AND;
                default:    DB.ALUControl = ADD;
            endcase
        end

        I_TYPE_MATH: begin 
            case (FB.instr[14:12])
                3'b000:     DB.ALUControl = ADD;
                3'b001:     DB.ALUControl = SLL;
                3'b010:     DB.ALUControl = SLT;
                3'b011:     DB.ALUControl = SLTU;
                3'b100:     DB.ALUControl = XOR;
                3'b101:     DB.ALUControl = (FB.instr[30] ? 4'h7 : 4'h6);
                3'b110:     DB.ALUControl = OR;
                3'b111:     DB.ALUControl = AND;
                default:    DB.ALUControl = ADD;
            endcase
        end
    endcase
end


initial begin
    int i;
    for ( i = 0; i < 32; i = i + 1) begin
        rf[i] = 32'b0;
        end
    end


         
always_ff @ (posedge clk) begin 

    if (WB.WE3 && !rst) begin
        assert (DB.A3 != 0) else  $warning("Useless Write to x0 detected: %h", WB.Result);
        if (DB.A3 != 0) rf[DB.A3] <= WB.Result;
    end
end

endmodule
        