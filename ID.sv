module Immediate_Generator(
    input logic [31:0] instr,
    output logic [31:0] imm,
    output Decode_Bundle DB,
    output logic [3:0] ALUControl,
    input logic clk,
    input logic RegW,
    input logic reset,
    input logic [4:0] A1,
    input logic [4:0] A2,
    input logic [4:0] A3,
    input logic [31:0] Result,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);
    localparam R =      7'b0110011;
    localparam I =      7'b0000011;
    localparam IALU =   7'b0010011; // I-Type
    localparam S =      7'b0100011;
    localparam B =      7'b1100011;
    localparam AUIPC =  7'b0010111; // U-Type
    localparam LUI =    7'b0110111; // U-Type
    localparam JAL =    7'b1101111; // J-Type
    localparam JALR =   7'b1100111; // I-Type

    localparam OP_R =      7'b0110011;
    localparam OP_I =      7'b0000011;
    localparam OP_IALU =   7'b0010011; // I-Type
    localparam OP_S =      7'b0100011;
    localparam OP_B =      7'b1100011;
    localparam OP_AUIPC =  7'b0010111; // U-Type
    localparam OP_LUI =    7'b0110111; // U-Type
    localparam OP_JAL =    7'b1101111; // J-Type
    localparam OP_JALR =   7'b1100111; // I-Type

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

    localparam FORCE_ADD        = 2'b00;
    localparam FORCE_SUB        = 2'b01;
    localparam CHECK_FUNCT_CODE =2'b10;
    localparam I_TYPE_MATH      = 2'b11;



logic [31:0] rf[31:0];

initial begin
    int i;
    for ( i = 0; i < 32; i = i + 1) begin
        rf[i] = 32'b0;
        end
    end

always_comb begin 
    Opcode = instr[6:0];

    case (Opcode)
        R:                      imm = 32'b0;

        I, JALR, IALU:          imm = {{20{instr[31]}},instr[31:20]};

        S:                      imm = {{20{instr[31]}},instr[31:25],instr[11:7]};

        B:                      imm = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};

        AUIPC, LUI:             imm = {instr[31:12],12'b0};
        
        JAL:                    imm = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0};

        default:                imm = 32'b0;
    endcase

    case (FB.instr[6:0]) 
        OP_R: begin // R- Type
            ctrl.RegW=1;     
            ctrl.MemW=0;     
            ctrl.Branch=0;       
            ctrl.Jump=0;     
            ctrl.ALUSrcB=0;      
            ctrl.ALUSrcA=0;      
            ctrl.ALUOp=CHECK_FUNCT_CODE;     
            ctrl.ImmSrc=R;
        end

        OP_IALU: begin // I- Type ALU
            ctrl.RegW=1;     
            ctrl.MemW=0;     
            ctrl.Branch=0;       
            ctrl.Jump=0;     
            ctrl.ALUSrcB=1;      
            ctrl.ALUSrcA=0;      
            ctrl.ALUOp=I_TYPE_MATH;     
            ctrl.ImmSrc=I;
        end

        OP_I: begin // Load
            ctrl.RegW=1;     
            ctrl.MemW=0;     
            ctrl.Branch=0;       
            ctrl.Jump=0;     
            ctrl.ALUSrcB=1;      
            ctrl.ALUSrcA=0;      
            ctrl.ALUOp=FORCE_ADD;     
            ctrl.ImmSrc=LOAD; 
        end

        OP_S: begin // Store
            ctrl.RegW=0;     
            ctrl.MemW=1;     
            ctrl.Branch=0;       
            ctrl.Jump=0;     
            ctrl.ALUSrcB=1;      
            ctrl.ALUSrcA=0;      
            ctrl.ALUOp=FORCE_ADD;     
            ctrl.ImmSrc=STORE;
        end

        OP_B: begin // Branch- Type
            ctrl.RegW=0;     
            ctrl.MemW=0;     
            ctrl.Branch=1;       
            ctrl.Jump=0;     
            ctrl.ALUSrcB=0;      
            ctrl.ALUSrcA=0;      
            ctrl.ALUOp=FORCE_SUB;                                      
            ctrl.ImmSrc=B;
            
        end

        OP_JAL: begin // JAL
            ctrl.RegW=0;
            ctrl.MemW=0;
            ctrl.Branch=0;
            ctrl.Jump=1;
            ctrl.ALUSrcB=0;
            ctrl.ALUSrcA=0;
            ctrl.ALUOp=FORCE_ADD;
            ctrl.ImmSrc=JAL;
        end

        OP_JALR: begin // JALR
            ctrl.RegW=0;     
            ctrl.MemW=0;     
            ctrl.Branch=0;       
            ctrl.Jump=1;     
            ctrl.ALUSrcB=1;      
            ctrl.ALUSrcA=0;      
            ctrl.ALUOp=FORCE_ADD;         
            ctrl.ImmSrc=JALR;
        end

        OP_LUI: begin // LUI
            ctrl.RegW=1;     
            ctrl.MemW=0;     
            ctrl.Branch=0;       
            ctrl.Jump=0;     
            ctrl.ALUSrcB=1;      
            ctrl.ALUSrcA=0;      
            ctrl.ALUOp=FORCE_ADD;      
            ctrl.ImmSrc=LUI;
        end

        OP_AUIPC: begin // AUIPC
            ctrl.RegW=1;     
            ctrl.MemW=0;     
            ctrl.Branch=0;       
            ctrl.Jump=0;     
            ctrl.ALUSrcB=1;      
            ctrl.ALUSrcA=1;      
            ctrl.ALUOp=FORCE_ADD;      
            ctrl.ImmSrc=AUIPC;
        end

        default: begin
            ctrl = 0;
            //$fatal;
            //$error("Unkown Opcode detected: %b",Opcode);

        end
    endcase

    case (ALUOp)
        FORCE_ADD: begin 
            ALUControl = ADD;
        end

        FORCE_SUB: begin 
            ALUControl = SUB;
        end

        CHECK_FUNCT_CODE: begin
            case (FB.instr[14:12])
                3'b000:     ALUControl = (instr[30] ? SUB : ADD);
                3'b001:     ALUControl = SLL;
                3'b010:     ALUControl = SLT;
                3'b011:     ALUControl = SLTU;
                3'b100:     ALUControl = XOR;
                3'b101:     ALUControl = (instr[30] ? SRA : SRL);
                3'b110:     ALUControl = OR;
                3'b111:     ALUControl = AND;
                default:    ALUControl = ADD;
            endcase
        end

        I_TYPE_MATH: begin 
            case (FB.instr[14:12])
                3'b000:     ALUControl = ADD;
                3'b001:     ALUControl = SLL;
                3'b010:     ALUControl = SLT;
                3'b011:     ALUControl = SLTU;
                3'b100:     ALUControl = XOR;
                3'b101:     ALUControl = (instr[30] ? SRA : SRL);
                3'b110:     ALUControl = OR;
                3'b111:     ALUControl = AND;
                default:    ALUControl = ADD;
            endcase
        end
    endcase
end



always_ff @ (posedge clk) begin 
    if (RegW && !reset) begin
        assert (A3 != 0) else  $warning("Useless Write to x0 detected: %h", Result);
        if (A3 != 0) rf[A3] <= Result;
    end
end

assign RD1 = ((A1 != 0) ? rf[A1] : 32'b0);
assign RD2 = ((A2 != 0) ? rf[A2] : 32'b0);

endmodule



        