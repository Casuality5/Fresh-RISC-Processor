module ALU(                                                     // Arithmetic Logic Unit
    input logic [31:0] SrcA, SrcB,
    input logic [3:0] ALUControl,
    output logic [31:0] ALUResult,
    output logic Zero, SLTFlagSigned, SLTFlagUnsigned
);
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

always_comb begin 
    case (ALUControl)
        ADD:        ALUResult = SrcA + SrcB;

        SUB:        ALUResult = SrcA - SrcB;

        AND:        ALUResult = SrcA & SrcB;

        OR:         ALUResult = SrcA | SrcB;

        XOR:        ALUResult = SrcA ^ SrcB;

        SLL:        ALUResult = SrcA << SrcB[4:0];

        SRL:        ALUResult = SrcA >> SrcB[4:0];

        SRA:        ALUResult = $signed(SrcA) >>> SrcB[4:0];

        SLT:       ALUResult = (($signed(SrcA) < ($signed(SrcB)))? 1 : 0);

        SLTU:      ALUResult = ((SrcA < SrcB)? 1 : 0);

        default:    ALUResult = 32'b0;
    endcase

    Zero = (ALUResult == 32'b0);
    SLTFlagSigned   =   (($signed(SrcA) < ($signed(SrcB)))? 1 : 0);
    SLTFlagUnsigned =   ((SrcA < SrcB)? 1 : 0);
end
endmodule

module PCTarget(
    input logic [31:0] Address, imm,
    output logic [31:0] Target_Address
);

assign Target_Address = Address + imm;

endmodule

module SrcBMux(                                                     // Source B Mux
    input logic [31:0] RD2,imm,
    input logic SrcBSelect,
    output logic [31:0] SrcB
);

assign SrcB = (SrcBSelect ? imm : RD2);
endmodule

module SrcAMux(                                                     // Source A Mux
    input logic [31:0] RD1,Address,
    input logic SrcASelect,
    output logic [31:0] SrcA
);

assign SrcA = (SrcASelect ? Address : RD1);
endmodule

module Branch_Producer import Pkg::*;(
    input bundle_decode_t ctrl,
    input logic [31:0] instr,
    input Zero, SLTFlagSigned, SLTFlagUnsigned,
    output logic Branch_taken,
    output logic [1:0] PCNext_select
); 



always_comb begin 
    Branch_taken = 0;
    PCNext_select = STEP_FORWARD;
    if (ctrl.Branch) begin
        case (instr[14:12]) 
        BEQ:  Branch_taken = Zero;
        BNE:  Branch_taken = !Zero;
        BLT:  Branch_taken = SLTFlagSigned;
        BGE:  Branch_taken = !SLTFlagSigned || Zero;
        BLTU: Branch_taken = SLTFlagUnsigned;
        BGEU: Branch_taken = !SLTFlagUnsigned || Zero;
        endcase
    end
    if (ctrl.Jump) begin
        PCNext_select = (ctrl.JALR) ? JUMP_TO_CALCULATED_REGISTER : JUMP_TO_LABEL;
        end
    else if (Branch_taken) begin
        PCNext_select = JUMP_TO_LABEL;
        end
    else begin
        PCNext_select = STEP_FORWARD;
        end
 end
endmodule

