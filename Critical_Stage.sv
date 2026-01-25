package Pkg;

    typedef enum logic [1:0] {
        RESULT_ALU = 2'b00,
        RESULT_MEM = 2'b01,
        RESULT_PC =  2'b10
    } Result_Mux_Case;
    
    typedef enum logic [1:0] {
        FORCE_ADD           = 2'b00,
        FORCE_SUB           = 2'b01,
        CHECK_FUNCT_CODE    = 2'b10,
        I_TYPE_MATH         = 2'b11
    } ALU_OP_Case;

    typedef enum logic [1:0] { 
        STEP_FORWARD                        = 2'b00,
        JUMP_TO_CALCULATED_REGISTER         = 2'b01,
        JUMP_TO_LABEL                       = 2'b10
    } PC_Next_Select_Case;

    typedef enum logic [3:0] { 
        R       =     4'h0,
        I       =     4'h1,
        LOAD    =     4'h2,
        STORE   =     4'h3,
        B       =     4'h4,
        JAL     =     4'h5,
        JALR    =     4'h6,
        LUI     =     4'h7,
        AUIPC   =     4'h8
    } Imm_Src_Case;
    
    typedef enum logic [2:0] {
        BEQ     =   3'b000,
        BNE     =   3'b001,
        BLT     =   3'b100,
        BGE     =   3'b101,
        BLTU    =   3'b110,
        BGEU    =   3'b111
    } Branch_Types_Case;

    typedef enum logic [2:0] {
        LOAD_BYTE = 3'b000,
        LOAD_HALF = 3'b001,
        LOAD_WORD = 3'b010,
        LOAD_BYTE_UNSIGNED = 3'b100,
        LOAD_HALF_UNSIGNED = 3'b101
    } Load_Type_Case;
    
    typedef enum logic [3:0] {
        ADD     =   4'h0,
        SUB     =   4'h1,
        ANDs    =   4'h2,
        ORs     =   4'h3,
        XORs    =   4'h4,
        SLL     =   4'h5,
        SRL     =   4'h6,
        SRA     =   4'h7,
        SLT     =   4'h8,
        SLTU    =   4'h9
    } ALUControl_Type_Case;

typedef struct packed {
    PC_Next_Select_Case PCNext_Select;
    logic [31:0] PC4;
    logic [31:0] ALUResult;
    logic Target_Address;
    logic [31:0] PCNext;
    logic [31:0] Address;
    logic [31:0] instr;

} Fetch_Bundle;

typedef struct packed {
    ALU_OP_Case        ALUOp;
    Imm_Src_Case       ImmSrc;
    Result_Mux_Case    ResultSelect;
    ALUControl_Type_Case ALUControl;
    logic [31:0] instr;
    logic [31:0] imm;
    logic [31:0] Address;
    logic RegW;
    logic MemW;
    logic Branch;
    logic Jump;
    logic ALUSrcA;
    logic ALUSrcB;
    logic [4:0] A1;
    logic [4:0] A2;
    logic [4:0] A3;
    logic [31:0] RD1;
    logic [31:0] RD2;
    logic [31:0] PC4;
} Decode_Bundle;

typedef struct packed {
    logic [31:0] SrcA;
    logic [31:0] SrcB;
    logic [31:0] ALUResult;
    logic Zero;
    logic SLTFlagSigned;
    logic SLTFlagUnsigned;
    logic [31:0] Address;
    logic [31:0] imm;
    logic [31:0] Target_Address;
    logic [31:0] RD2;
    logic SrcBSelect;
    logic [31:0] RD1;
    logic [31:0] PC4;
    logic [4:0] A3;
    logic SrcASelect;
    ALU_OP_Case        ALUOp;
    Imm_Src_Case       ImmSrc;
    Result_Mux_Case    ResultSelect;
    PC_Next_Select_Case PCNext_Select;
    ALUControl_Type_Case ALUControl;
    logic RegW;
    logic MemW;
    logic Branch;
    logic Jump;
    logic ALUSrcA;
    logic ALUSrcB;
    logic [31:0] instr;
    logic Branch_taken;
} Execute_Bundle;

typedef struct packed {
    logic WE;
    logic [31:0] instr;
    logic [31:0] DataMemoryAddress;
    logic [31:0] WD;
    logic [31:0] DataMemoryRead;
    logic [31:0] ALUResult;
    logic [31:0] FinalDataMemoryRead;
    logic [31:0] ReadData;
    logic [4:0] A3;
    logic RegW;
    Result_Mux_Case    ResultSelect;
    logic [31:0] PC4;
    
} Memory_Bundle;

typedef struct packed {
    Result_Mux_Case ResultSelect;
    logic [31:0] ALUResult;
    logic [31:0] FinalDataMemoryRead;
    logic [31:0] PC4;
    logic [31:0] Result;
    logic  WE3;
    logic [4:0] A3;
    logic RegW;
} WriteBack_Bundle;


endpackage

//======================================================================================

import Pkg::*;

module Fetch #(
    parameter Size = 1024
)(
    input logic            clk,
    input logic            rst,
    input Execute_Bundle   EB,
    output Fetch_Bundle    FB
);

logic [31:0] pc_next;
logic [31:0] address;
logic [31:0] pc4;
logic [31:0] instr_out;
logic [31:0] im[Size-1:0];

assign pc4 = address + 32'h4;

always_comb begin 
    if (rst) begin
        pc_next = 32'b0;
        end
    case (EB.PCNext_Select)
        STEP_FORWARD:                       pc_next = EB.Address + 32'h4;

        JUMP_TO_CALCULATED_REGISTER:        pc_next = EB.ALUResult;

        JUMP_TO_LABEL:                      pc_next = EB.Target_Address;

        default:                            pc_next = EB.Address + 32'h4;
    endcase
end


always_ff @ (posedge clk or posedge rst) begin 
    if (rst) begin 
        address <= 32'b0;
    end

    else begin 
        address <= pc_next;
    end
end

initial begin
    $readmemh("Program.mem",im);
end

assign instr_out = im[address[31:2] % Size];


assign FB.PCNext = pc_next;
assign FB.Address = address;
assign FB.PC4 = pc4;
assign FB.instr = instr_out;
endmodule

//================================================================================

import Pkg::*;

module reg_IF_ID (
    input  logic clk, rst, clr,
    input  Fetch_Bundle  d,
    output Fetch_Bundle  q
);
    always_ff @(posedge clk) begin
        if (rst || clr) q <= '0;
        else              q <= d;
    end
endmodule
//=================================================================================
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



logic [31:0] rf[31:0];
always_comb begin
    
    DB       = '0;
    DB.ALUControl = ADD;
    DB.instr = FB.instr;
    DB.A1    = FB.instr[19:15];
    DB.A2    = FB.instr[24:20];
    DB.A3    = FB.instr[11:7];

    case (FB.instr[6:0]) 
        Rt: begin // R- Type
            DB.RegW=1;     
            DB.MemW=0;     
            DB.Branch=0;       
            DB.Jump=0;     
            DB.ALUSrcB=0;      
            DB.ALUSrcA=0;      
            DB.ALUOp=CHECK_FUNCT_CODE;
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
            DB.A3 = FB.instr[11:7];
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
            DB.A3 = FB.instr[11:7];
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
            DB.A3 = FB.instr[11:7];
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
            DB.A3 = FB.instr[11:7];
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
            DB.A3 = FB.instr[11:7];
            
        end

        JALt: begin // JAL
            DB.RegW=0;
            DB.MemW=0;
            DB.Branch=0;
            DB.Jump=1;
            DB.ALUSrcB=0;
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
            DB.ImmSrc=JAL;
            DB.ResultSelect=RESULT_PC;
            DB.imm = {{12{FB.instr[31]}},FB.instr[19:12],FB.instr[20],FB.instr[30:21],1'b0};
            DB.A3 = FB.instr[11:7];
        end

        JALRt: begin // JALR
            DB.RegW=0;     
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
            DB.A3 = FB.instr[11:7];
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
            DB.A3 = FB.instr[11:7];
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
            DB.A3 = FB.instr[11:7];
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
            DB.A3 = FB.instr[11:7];
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

assign DB.RD1 = (DB.A1 == 0) ? 32'b0 : 
                ((DB.A1 == WB.A3) && WB.RegW) ? WB.Result : rf[DB.A1];

assign DB.RD2 = (DB.A2 == 0) ? 32'b0 : 
                ((DB.A2 == WB.A3) && WB.RegW) ? WB.Result : rf[DB.A2];

         
always_ff @(negedge clk) begin // Try negedge to solve race conditions!
    if (rst) begin
        // Reset logic
        for (int i = 0; i < 32; i++) begin
            rf[i] <= 32'b0;
            end
    end else if (WB.RegW) begin
        if (WB.A3 != 5'b0) begin
            rf[WB.A3] <= WB.Result;
        end
    end
end

endmodule
        
//=================================================================================================

import Pkg::*;

module reg_ID_EX (
    input  logic clk, rst,
    input  Decode_Bundle d,
    output Decode_Bundle q
);
    always_ff @(posedge clk) begin
        if (rst) q <= '0;
        else     q <= d;
    end
endmodule

//=================================================================================================

import Pkg::*; 

module Execute (
    input  Decode_Bundle  DB,
    output Execute_Bundle EB
);
    logic [31:0] src_a, src_b;
    logic [31:0] immediate;
    logic [31:0] address;
    logic        sltfs, sltfu, zero;

    assign address   = DB.Address;
    assign immediate = DB.imm;
    assign src_a = (DB.ALUSrcA ? address   : DB.RD1);
    assign src_b = (DB.ALUSrcB ? immediate : DB.RD2);

 
    always_comb begin 
        EB = '0;
        EB.PCNext_Select = STEP_FORWARD;


        case (DB.ALUControl)
            ADD: EB.ALUResult = src_a + src_b;
            SUB: EB.ALUResult = src_a - src_b;
            ANDs: EB.ALUResult = src_a & src_b;
            ORs: EB.ALUResult = src_a | src_b;
            XORs: EB.ALUResult = src_a ^ src_b;
            SLL: EB.ALUResult = src_a << src_b[4:0];
            SRL: EB.ALUResult = src_a >> src_b[4:0];
            SRA: EB.ALUResult = $signed(src_a) >>> src_b[4:0];
            SLT: EB.ALUResult = (($signed(src_a) < $signed(src_b)) ? 32'h1 : 32'h0);
            SLTU: EB.ALUResult = ((src_a < src_b) ? 32'h1 : 32'h0);
            default: EB.ALUResult = 32'b0;
        endcase

        zero  = (EB.ALUResult == 32'b0);
        sltfs = ($signed(src_a) < $signed(src_b));
        sltfu = (src_a < src_b);


        EB.Branch_taken = 0;
        if (DB.Branch) begin
            case (DB.instr[14:12]) 
                3'b000: EB.Branch_taken = zero;
                3'b001: EB.Branch_taken = !zero;
                3'b100: EB.Branch_taken = sltfs;
                3'b101: EB.Branch_taken = !sltfs || zero;
                3'b110: EB.Branch_taken = sltfu;
                3'b111: EB.Branch_taken = !sltfu || zero;
                default: EB.Branch_taken = 0;
            endcase
        end

        if (DB.Jump) begin
            EB.PCNext_Select = (DB.instr[6:0] == 7'b1100111) ? JUMP_TO_CALCULATED_REGISTER : JUMP_TO_LABEL;
        end else if (EB.Branch_taken) begin
            EB.PCNext_Select = JUMP_TO_LABEL;
        end else begin
            EB.PCNext_Select = STEP_FORWARD;
        end

        EB.Target_Address = address + immediate;
        EB.instr          = DB.instr;      
        EB.RD2            = DB.RD2;
        EB.A3             = DB.A3;         
        EB.RegW           = DB.RegW;       
        EB.MemW           = DB.MemW;       
        EB.ResultSelect   = DB.ResultSelect;
        EB.PC4            = DB.PC4;
    end

endmodule

//=============================================================================================================

import Pkg::*;

module reg_EX_MEM (
    input  logic clk, rst,
    input  Execute_Bundle d,
    output Execute_Bundle q
);
    always_ff @(posedge clk) begin
        if (rst) begin 
        q <= '0;
        end
        else     q <= d;
    end
endmodule

//================================================================================================================

import Pkg::*;

module Memory #(parameter Size = 1024) (
    input  logic           clk, rst,
    input  Execute_Bundle  EB, // Incoming trunk
    output Memory_Bundle   MB  // Outgoing trunk
);

    // --- Workbench ---
    logic [31:0] dm [Size-1:0];
    logic [31:0] raw_word;
    logic [31:0] final_read_data;
    logic [31:0] mask_data, mask_inv;
    logic [7:0]  byte_val;
    logic [15:0] half_val;
    logic [31:0] addr;

    assign addr = EB.ALUResult[31:2]; // Word-aligned address
    assign raw_word = dm[addr];      // Read the whole word first

    // 1. STORE LOGIC (The "Masking" workbench)
    always_comb begin
        mask_data = 32'b0;
        mask_inv  = 32'hFFFF_FFFF;

        case(EB.instr[14:12])
            3'b000: begin // SB (Store Byte)
                case (EB.ALUResult[1:0])
                    2'h0: begin mask_data = {24'b0, EB.RD2[7:0]};        mask_inv = 32'hFFFF_FF00; end
                    2'h1: begin mask_data = {16'b0, EB.RD2[7:0], 8'b0};  mask_inv = 32'hFFFF_00FF; end
                    2'h2: begin mask_data = {8'b0,  EB.RD2[7:0], 16'b0}; mask_inv = 32'hFF00_FFFF; end
                    2'h3: begin mask_data = {EB.RD2[7:0], 24'b0};        mask_inv = 32'h00FF_FFFF; end
                endcase
            end
            3'b001: begin // SH (Store Half)
                case(EB.ALUResult[1])
                    1'b0: begin mask_data = {16'b0, EB.RD2[15:0]};       mask_inv = 32'hFFFF_0000; end
                    1'b1: begin mask_data = {EB.RD2[15:0], 16'b0};       mask_inv = 32'h0000_FFFF; end
                endcase
            end
            default: begin mask_data = EB.RD2; mask_inv = 32'b0; end // SW (Store Word)
        endcase
    end

    // 2. LOAD LOGIC (The "Extension" workbench)
    always_comb begin
        // Select Byte
        case (EB.ALUResult[1:0])
            2'b00: byte_val = raw_word[7:0];
            2'b01: byte_val = raw_word[15:8];
            2'b10: byte_val = raw_word[23:16];
            2'b11: byte_val = raw_word[31:24];
        endcase
        // Select Half
        half_val = (EB.ALUResult[1]) ? raw_word[31:16] : raw_word[15:0];

        // Sign Extension
        case (EB.instr[14:12])
            LOAD_BYTE:          final_read_data = {{24{byte_val[7]}}, byte_val};
            LOAD_HALF:          final_read_data = {{16{half_val[15]}}, half_val};
            LOAD_WORD:          final_read_data = raw_word;
            LOAD_BYTE_UNSIGNED: final_read_data = {24'b0, byte_val};
            LOAD_HALF_UNSIGNED: final_read_data = {16'b0, half_val};
            default:            final_read_data = raw_word;
        endcase
    end

    // 3. PHYSICAL MEMORY WRITE
    always_ff @(posedge clk) begin
        if (EB.MemW && !rst) begin
            if (EB.instr[14:12] == 3'b010) // SW
                dm[addr] <= EB.RD2;
            else
                dm[addr] <= (raw_word & mask_inv) | mask_data;
        end
    end

    // 4. PACKING THE TRUNK
    always_comb begin
        MB = '0;
        MB.instr        = EB.instr;
        MB.ALUResult    = EB.ALUResult;
        MB.ReadData     = final_read_data; // The aligned/extended data
        MB.A3           = EB.A3;
        MB.RegW         = EB.RegW;
        MB.ResultSelect = EB.ResultSelect;
        MB.PC4          = EB.PC4;
    end

endmodule

//===============================================================================================================

import Pkg::*;

module reg_MEM_WB (
    input  logic           clk, rst,
    input  Memory_Bundle   d,   // Data coming from Memory_Stage
    output Memory_Bundle   q   // Data going to ResultMux (Writeback)
);

    always_ff @(posedge clk) begin
        if (rst) begin
            q <= '0; // Clear the trunk on reset
        end else begin
            q <= d;  // Hand off the trunk to the final stage
        end
    end

endmodule

//================================================================================================================

module ResultMux import Pkg::*; (
    input  Memory_Bundle    MB, // Final trunk from Memory
    output WriteBack_Bundle WB  // Trunk going back to the start
);

    always_comb begin 
        // 1. Initialize to clear any floating wires
        WB = '0;
        
        // 2. The Result Mux (The Decision)
        case (MB.ResultSelect)
            RESULT_ALU: WB.Result = MB.ALUResult;
            RESULT_MEM: WB.Result = MB.ReadData; // Ensure this matches your MB struct field
            RESULT_PC:  WB.Result = MB.PC4;
            default:    WB.Result = MB.ALUResult;
        endcase

        // 3. THE CRITICAL STEP: Pass through the write controls
        // Without these, the Register File won't know where to save the Result!
        WB.A3   = MB.A3;   
        WB.RegW = MB.RegW; 
    end

endmodule

//===================================================================================================================

`timescale 1ns / 1ps

module tb();
    logic clk;
    logic rst;

    // Instantiate your Core
    Top dut (
        .clk(clk),
        .rst(rst)
    );

    // 1. Generate Clock (100MHz)
    always #5 clk = ~clk;

    // 2. The Test Sequence
    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        
        // Hold reset for a few cycles
        #20;
        rst = 0;

        // Run for enough time to see the instructions pass through all 5 stages
        #100000;
        
        $display("Simulation Finished. Check the Waveform!");
    end
endmodule