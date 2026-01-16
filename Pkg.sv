package Pkg;

    typedef enum logic [1:0] {
        RESULT_ALU = 2'b00,
        RESULT_MEM = 2'b01,
        RESULT_PC =  2'b10
        } result_mux_t;
    
    typedef enum logic [1:0] {
        FORCE_ADD           = 2'b00,
        FORCE_SUB           = 2'b01,
        CHECK_FUNCT_CODE    = 2'b10,
        I_TYPE_MATH         = 2'b11
        } alu_op_t;

    typedef enum logic [1:0] { 
        STEP_FORWARD                        = 2'b00,
        JUMP_TO_CALCULATED_REGISTER         = 2'b01,
        JUMP_TO_LABEL                       = 2'b10
        } pc_next_select_t;

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
        } imm_src_t;
    
    typedef enum logic [2:0] {
        BEQ     =   3'b000,
        BNE     =   3'b001,
        BLT     =   3'b100,
        BGE     =   3'b101,
        BLTU    =   3'b110,
        BGEU    =   3'b111
    } branch_type_t;

    typedef enum logic [2:0] {
        LOAD_BYTE = 3'b000,
        LOAD_HALF = 3'b001,
        LOAD_WORD = 3'b010,
        LOAD_BYTE_UNSIGNED = 3'b100,
        LOAD_HALF_UNSIGNED = 3'b101
    } load_type_t;

    typedef struct packed {
        alu_op_t        ALUOp;
        imm_src_t       ImmSrc;
        result_mux_t    ResultSelect;
        logic RegW;
        logic MemR;
        logic MemW;
        logic Branch;
        logic Jump;
        logic ALUSrcA;
        logic ALUSrcB;
        pc_next_select_t PCNext_select;
    } bundle_decode_t;
endpackage