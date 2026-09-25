import Pkg::*; 

module Execute (
    input  Decode_Bundle  DB,
    input  Memory_Bundle  MB,
    input logic [31:0] MB_ALUResult,
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
    logic [31:0] MB_ForwardData;

    // Calculate correct result from MEM stage (Load data, PC4, or ALU result)
    assign MB_ForwardData = (MB.ResultSelect == RESULT_MEM) ? MB.FinalDataMemoryRead :
                            (MB.ResultSelect == RESULT_PC)  ? MB.PC4 : MB_ALUResult;

    // Target Address calculation for Branches and JAL
    assign Target_Address = DB.Address + DB.imm;
    

    always_comb begin 
        EB = '0;
        EB.instr        = DB.instr;      
        // EB.RD2           = DB.RD2;
        EB.RD1          = DB.RD1;
        EB.rd           = DB.rd;         
        EB.RegW         = DB.RegW;       
        EB.WE         = DB.MemW;       
        EB.ResultSelect = DB.ResultSelect;
        EB.PC4          = DB.PC4;
        EB.Address      = DB.Address;
//        EB.Target_Address = DB.PC4 + 4;
        EB.Target_Address = 32'b0; 
        EB.Jump           = DB.Jump;
        EB.RS1            = DB.A1; // This Added
        EB.RS2            = DB.A2; // This Added
        
        
        
        // NEW MUXES FOR BYPASSING
        case (ForwardAE)
            2'b00: RD1E = DB.RD1;

            2'b01: RD1E = WD3; // Use WD3 port from Result stage

            2'b10: RD1E = MB_ForwardData; // Use correct result from MEM stage

            default: RD1E = DB.RD1;
        endcase
        case (ForwardBE)
            2'b00: RD2E = DB.RD2;

            2'b01: RD2E = WD3; // Use WD3 port from Result stage

            2'b10: RD2E = MB_ForwardData; // Use correct result from MEM stage

            default: RD2E = DB.RD2;
        endcase

        EB.RD2 = RD2E;

        src_a = (DB.instr[6:0] == 7'b0110111) ? 32'b0 : (DB.ALUSrcA ? DB.Address : RD1E);
        src_b = (DB.ALUSrcB ? DB.imm     : RD2E);

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
        
        if (DB.Jump) begin
            EB.ALUResult = DB.PC4;
        end

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
        
        if (DB.Jump) begin
            EB.Target_Address = (DB.instr[6:0] == 7'b1100111) ? ((src_a + src_b) & ~32'h1) : Target_Address;
            PCNext_Select = (DB.instr[6:0] == 7'b1100111) ? JUMP_TO_CALCULATED_REGISTER : JUMP_TO_LABEL;
        end else if (EB.Branch_taken) begin
            EB.Target_Address = Target_Address;
            PCNext_Select = JUMP_TO_LABEL;
        end else begin
            PCNext_Select = STEP_FORWARD;
        end
        
    end
 assign ALUResult_to_Fetch = (DB.Jump && DB.instr[6:0] == 7'b1100111) ?
    ((src_a + src_b) & ~32'h1) :
    EB.ALUResult;//EB.ALUResult;
endmodule