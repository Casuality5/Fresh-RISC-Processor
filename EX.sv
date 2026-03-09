import Pkg::*; 

module Execute (
    input  Decode_Bundle  DB,
    input  Memory_Bundle MB,
    input [31:0] WD3,
    input [1:0] ForwardAE,
    input [1:0] ForwardBE,
    output Execute_Bundle EB,
    // Individual Fast-Path Outputs
    output PC_Next_Select_Case PCNext_Select,
    output logic [31:0]        Target_Address,
    output logic [31:0]        ALUResult_to_Fetch
);
    logic [31:0] src_a, src_b;
    logic        zero, sltfs, sltfu;
    logic [31:0] RD1E;
    logic [31:0] RD2E;
    // Target Address calculation for Branches and JAL
    assign Target_Address = DB.Address + DB.imm;
    assign src_a = (DB.ALUSrcA ? DB.Address : RD1E);
    assign src_b = (DB.ALUSrcB ? DB.imm     : RD2E);

    always_comb begin 
        EB.instr        = DB.instr;      
        EB.RD2           = DB.RD2;
        EB.rd           = DB.rd;         
        EB.RegW         = DB.RegW;       
        EB.WE         = DB.MemW;       
        EB.ResultSelect = DB.ResultSelect;
        EB.PC4          = DB.PC4;
        EB.Address      = DB.Address;
        ALUResult_to_Fetch = EB.ALUResult;
        
        
        // NEW MUXES FOR BYPASSING
        case (ForwardAE)
            2'b00: RD1E = EB.RD1;

            2'b01: RD1E = WD3; // Use WD3 port from Result stage

            2'b10: RD1E = MB.ALUResult; //Use ALUResult port from MEM stage

            default: RD1E = EB.RD1;
        endcase
        case (ForwardBE)
            2'b00: RD2E = EB.RD2;

            2'b01: RD2E = WD3; // Use WD3 port from Result stage

            2'b10: RD2E = MB.ALUResult; //Use ALUResult port from MEM stage

            default: RD2E = EB.RD2;
        endcase

        // ALU Math
        case (DB.ALUControl)
            ADD:  EB.ALUResult = src_a + src_b;
            SUB:  EB.ALUResult = src_a - src_b;
            ANDs: EB.ALUResult = src_a & src_b;
            ORs:  EB.ALUResult = src_a | src_b;
            XORs: EB.ALUResult = src_a ^ src_b;
            SLL:  EB.ALUResult = src_a << src_b[4:0];
            SRL:  EB.ALUResult = src_a >> src_b[4:0];
            SRA:  EB.ALUResult = $signed(src_a) >>> src_b[4:0];
            SLT:  EB.ALUResult = (($signed(src_a) < $signed(src_b)) ? 32'h1 : 32'h0);
            SLTU: EB.ALUResult = ((src_a < src_b) ? 32'h1 : 32'h0);
            default: EB.ALUResult = 32'b0;
        endcase
        

        // Branch condition logic
        zero  = ($signed(src_a) == $signed(src_b));
        sltfs = ($signed(src_a) < $signed(src_b));
        sltfu = (src_a < src_b);

        EB.Branch_taken = 1'b0;
        if (DB.Branch) begin
            case (DB.instr[14:12])
                3'b000: EB.Branch_taken = zero;   // BEQ
                3'b001: EB.Branch_taken = !zero;  // BNE
                3'b100: EB.Branch_taken = sltfs;  // BLT
                3'b101: EB.Branch_taken = !sltfs; // BGE
                3'b110: EB.Branch_taken = sltfu;  // BLTU
                3'b111: EB.Branch_taken = !sltfu; // BGEU
                default: EB.Branch_taken = 1'b0;
            endcase
        end

        // Redirection Logic (The Fast-Path Decision)
        if (DB.Jump) begin
            PCNext_Select = (DB.instr[6:0] == 7'b1100111) ? JUMP_TO_CALCULATED_REGISTER : JUMP_TO_LABEL;
        end else if (EB.Branch_taken) begin
            PCNext_Select = JUMP_TO_LABEL;
        end else begin
            PCNext_Select = STEP_FORWARD;
        end

        // Pipeline Passthroughs
        
    end
 
endmodule