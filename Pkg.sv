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
    logic [31:0] instr;
    logic [31:0] imm;
    logic [3:0] ALUControl;
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
} Decode_Bundle;

typedef struct packed {
    logic [31:0] SrcA;
    logic [31:0] SrcB;
    logic [3:0] ALUControl;
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
    logic SrcASelect;
    ALU_OP_Case        ALUOp;
    Imm_Src_Case       ImmSrc;
    Result_Mux_Case    ResultSelect;
    PC_Next_Select_Case PCNext_Select;
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
} Memory_Bundle;

typedef struct packed {
    Result_Mux_Case ResultSelect;
    logic [31:0] ALUResult;
    logic [31:0] FinalDataMemoryRead;
    logic [31:0] PC4;
    logic [31:0] Result;
    logic  WE3;
} WriteBack_Bundle;


endpackage