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


        case (DB.ALUControl)
            4'h0: EB.ALUResult = src_a + src_b;
            4'h1: EB.ALUResult = src_a - src_b;
            4'h2: EB.ALUResult = src_a & src_b;
            4'h3: EB.ALUResult = src_a | src_b;
            4'h4: EB.ALUResult = src_a ^ src_b;
            4'h5: EB.ALUResult = src_a << src_b[4:0];
            4'h6: EB.ALUResult = src_a >> src_b[4:0];
            4'h7: EB.ALUResult = $signed(src_a) >>> src_b[4:0];
            4'h8: EB.ALUResult = (($signed(src_a) < $signed(src_b)) ? 32'h1 : 32'h0);
            4'h9: EB.ALUResult = ((src_a < src_b) ? 32'h1 : 32'h0);
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