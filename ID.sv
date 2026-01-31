import Pkg::*;


module Decode(
    input clk,
    input rst,
    input Fetch_Bundle FB,
    input logic [4:0] A3,
    input logic WE3,
    input logic [31:0] WD3,
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



logic [31:0] rf[31:0];
always_comb begin
    
    DB       = '0;
    DB.ALUControl = ADD;
    DB.instr = FB.instr;
    DB.A1    = FB.instr[19:15];
    DB.A2    = FB.instr[24:20];
    DB.rd    = FB.instr[11:7];
    DB.RD1 = (DB.A1 == 0) ? 32'b0 :((DB.A1 == A3) && WE3) ? WD3 : rf[DB.A1];
    DB.RD2 = (DB.A2 == 0) ? 32'b0 :((DB.A2 == A3) && WE3) ? WD3 : rf[DB.A2];
    DB.PC4 =  FB.Address + 32'd4; 

    case (FB.instr[6:0]) 
        Rt: begin // R- Type
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=0;      
            DB.ALUSrcA=0;      
            DB.ALUOp=CHECK_FUNCT_CODE;
            DB.ALUControl = ADD;
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                        endcase
                    end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                        endcase
                    end
        
                default : DB.ALUControl = ADD;
                endcase     
            DB.ImmSrc=R;
            DB.ResultSelect=RESULT_ALU;
            DB.imm = 32'b0;
            DB.rd = FB.instr[11:7];
        end

        IALUt: begin // I- Type ALU
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=I_TYPE_MATH;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
                endcase    
            DB.ImmSrc=I;
            DB.ResultSelect=RESULT_ALU;
            DB.imm = {{20{FB.instr[31]}},FB.instr[31:20]};
            DB.rd = FB.instr[11:7];
        end

        It: begin // Load
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_ADD;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
            endcase   
            DB.ImmSrc=LOAD;
            DB.ResultSelect= RESULT_MEM;
            DB.imm = {{20{FB.instr[31]}},FB.instr[31:20]};
            DB.rd = FB.instr[11:7];
        end

        St: begin // Store
            DB.RegW=0;     
            DB.MemW=1;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_ADD;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
            endcase     
            DB.ImmSrc=STORE;
            DB.ResultSelect=RESULT_ALU;
            DB.imm = {{20{FB.instr[31]}},FB.instr[31:25],FB.instr[11:7]};
            DB.rd = FB.instr[11:7];
        end

        Bt: begin // Branch- Type
            DB.RegW=0;     
            DB.MemW=0;     
            DB.Branch=1;       
            DB.Jump=0;     
            DB.ALUSrcB=0;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_SUB;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
            endcase                                      
            DB.ImmSrc=B;
            DB.ResultSelect=RESULT_ALU;
            DB.imm = {{20{FB.instr[31]}},FB.instr[7],FB.instr[30:25],FB.instr[11:8],1'b0};
            DB.rd = FB.instr[11:7];
            
        end

        JALt: begin // JAL
            DB.RegW=1;
            DB.MemW=0;
            DB.Branch=0;
            DB.Jump=1;
            DB.ALUSrcB=1;
            DB.ALUSrcA=1;
            DB.ALUOp=FORCE_ADD;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
            endcase
            DB.ImmSrc=JAL;
            DB.ResultSelect=RESULT_PC;
            DB.imm = {{12{FB.instr[31]}},FB.instr[19:12],FB.instr[20],FB.instr[30:21],1'b0};
            DB.rd = FB.instr[11:7];
        end

        JALRt: begin // JALR
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=1;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_ADD;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
            endcase         
            DB.ImmSrc=JALR;
            DB.ResultSelect=RESULT_PC;
            DB.imm = {{20{FB.instr[31]}},FB.instr[31:20]};
            DB.rd = FB.instr[11:7];
        end

        LUIt: begin // LUI
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=0;      
            DB.ALUOp=FORCE_ADD;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
            endcase      
            DB.ImmSrc=LUI;
            DB.ResultSelect=RESULT_ALU;
            DB.imm = {FB.instr[31:12],12'b0};
            DB.rd = FB.instr[11:7];
        end

        AUIPCt: begin // AUIPC
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=1;      
            DB.ALUSrcA=1;      
            DB.ALUOp=FORCE_ADD;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
            endcase      
            DB.ImmSrc=AUIPC;
            DB.ResultSelect=RESULT_ALU;
            DB.imm = {FB.instr[31:12],12'b0};
            DB.rd = FB.instr[11:7];
        end
        
        default: begin 
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=0;      
            DB.ALUSrcA=0;      
            DB.ALUOp=CHECK_FUNCT_CODE;
            case (4'(DB.ALUOp))
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
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end

                I_TYPE_MATH: begin 
                    case (FB.instr[14:12])
                        3'b000:     DB.ALUControl = ADD;
                        3'b001:     DB.ALUControl = SLL;
                        3'b010:     DB.ALUControl = SLT;
                        3'b011:     DB.ALUControl = SLTU;
                        3'b100:     DB.ALUControl = XORs;
                        3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
                        3'b110:     DB.ALUControl = ORs;
                        3'b111:     DB.ALUControl = ANDs;
                    endcase
                end
        
                default : DB.ALUControl = ADD;
            endcase     
            DB.ImmSrc=R;
            DB.ResultSelect=RESULT_ALU;
            DB.imm = 32'b0;
            DB.rd = FB.instr[11:7];
            end

    endcase



//    case (4'(DB.ALUOp))
//        FORCE_ADD: begin 
//            DB.ALUControl = ADD;
//        end

//        FORCE_SUB: begin 
//            DB.ALUControl = SUB;
//        end

//        CHECK_FUNCT_CODE: begin
//            case (FB.instr[14:12])
//                3'b000:     DB.ALUControl = (FB.instr[30] ? SUB : ADD);
//                3'b001:     DB.ALUControl = SLL;
//                3'b010:     DB.ALUControl = SLT;
//                3'b011:     DB.ALUControl = SLTU;
//                3'b100:     DB.ALUControl = XORs;
//                3'b101:     DB.ALUControl = (FB.instr[30] ? SRA : SRL);
//                3'b110:     DB.ALUControl = ORs;
//                3'b111:     DB.ALUControl = ANDs;
//            endcase
//        end

//        I_TYPE_MATH: begin 
//            case (FB.instr[14:12])
//                3'b000:     DB.ALUControl = ADD;
//                3'b001:     DB.ALUControl = SLL;
//                3'b010:     DB.ALUControl = SLT;
//                3'b011:     DB.ALUControl = SLTU;
//                3'b100:     DB.ALUControl = XORs;
//                3'b101:     DB.ALUControl = (FB.instr[30] ? 4'h7 : 4'h6);
//                3'b110:     DB.ALUControl = ORs;
//                3'b111:     DB.ALUControl = ANDs;
//            endcase
//        end
        
//        default : DB.ALUControl = ADD;
//    endcase
end


initial begin
    int i;
    for ( i = 0; i < 32; i = i + 1) begin
        rf[i] = 32'b0;
        end
    end 
      
always_ff @(negedge clk) begin // Try negedge to solve race conditions!
    if (rst) begin
        // Reset logic
        for (int i = 0; i < 32; i++) begin
            rf[i] <= 32'b0;
            end
    end else if (WE3) begin
        if (A3 != 5'b0) begin
            rf[A3] <= WD3;
        end
    end
end

endmodule
        