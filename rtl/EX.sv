`timescale 1ns / 1ps

import Pkg::*; 

module Execute (
    input  Decode_Bundle  DB,
    input  Memory_Bundle  MB,
    input  logic [31:0]   MB_ALUResult,
    input  logic [31:0]   WD3,
    input  logic [1:0]    ForwardAE,
    input  logic [1:0]    ForwardBE,
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
    logic [31:0] jalr_target;

    // 1. Result MUX from Memory Stage
    assign MB_ForwardData = (MB.ResultSelect == RESULT_MEM) ? MB.DataMemoryRead :
                            (MB.ResultSelect == RESULT_PC)  ? MB.PC4 : MB_ALUResult;

    // 2. Parallel Target Adders (Calculated outside main ALU - 0 extra logic levels)
    assign Target_Address = DB.Address + DB.imm;
    assign jalr_target    = (RD1E + DB.imm) & ~32'h1;

    // 3. Fast Forwarding MUXes
    always_comb begin
        case (ForwardAE)
            2'b01:   RD1E = WD3;
            2'b10:   RD1E = MB_ForwardData;
            default: RD1E = DB.RD1;
        endcase

        case (ForwardBE)
            2'b01:   RD2E = WD3;
            2'b10:   RD2E = MB_ForwardData;
            default: RD2E = DB.RD2;
        endcase
    end

    // ALUSrc MUXes
    assign src_a = DB.ALUSrcA ? DB.Address : RD1E;
    assign src_b = DB.ALUSrcB ? DB.imm     : RD2E;

    // 4. Branch Comparators (Runs IN PARALLEL with ALU, NOT after CARRY4!)
    assign zero  = (RD1E == RD2E);
    assign sltfs = ($signed(RD1E) < $signed(RD2E));
    assign sltfu = (RD1E < RD2E);

    always_comb begin
        EB.Branch_taken = 1'b0;
        if (DB.Branch) begin
            case (DB.instr[14:12])
                3'b000:  EB.Branch_taken = zero;   // BEQ
                3'b001:  EB.Branch_taken = !zero;  // BNE
                3'b100:  EB.Branch_taken = sltfs;  // BLT
                3'b101:  EB.Branch_taken = !sltfs; // BGE
                3'b110:  EB.Branch_taken = sltfu;  // BLTU
                3'b111:  EB.Branch_taken = !sltfu; // BGEU
                default: EB.Branch_taken = 1'b0;
            endcase
        end
    end

    // 5. Main ALU Operation
    always_comb begin
        case (DB.ALUControl)
            ADD:     EB.ALUResult = src_a + src_b;
            SUB:     EB.ALUResult = src_a - src_b;
            ANDs:    EB.ALUResult = src_a & src_b;
            ORs:     EB.ALUResult = src_a | src_b;
            XORs:    EB.ALUResult = src_a ^ src_b;
            SLL:     EB.ALUResult = src_a << src_b[4:0];
            SRL:     EB.ALUResult = src_a >> src_b[4:0];
            SRA:     EB.ALUResult = $signed(src_a) >>> src_b[4:0];
            SLT:     EB.ALUResult = sltfs ? 32'h1 : 32'h0;
            SLTU:    EB.ALUResult = sltfu ? 32'h1 : 32'h0;
            default: EB.ALUResult = 32'b0;
        endcase

        if (DB.Jump) begin
            EB.ALUResult = DB.PC4;
        end
    end

    // 6. Pipeline Bundle Outputs
    always_comb begin
        EB.instr        = DB.instr;      
        EB.RD1          = DB.RD1;
        EB.RD2          = RD2E;
        EB.rd           = DB.rd;         
        EB.RegW         = DB.RegW;       
        EB.WE           = DB.MemW;       
        EB.ResultSelect = DB.ResultSelect;
        EB.PC4          = DB.PC4;
        EB.Address      = DB.Address;
        EB.Jump         = DB.Jump;
        EB.RS1          = DB.A1; 
        EB.RS2          = DB.A2; 
        
        if (DB.Jump) begin
            EB.Target_Address = (DB.instr[6:0] == 7'b1100111) ? jalr_target : Target_Address;
        end else begin
            EB.Target_Address = Target_Address;
        end
    end

    // 7. Fast Decoded Output to Fetch Stage
    assign PCNext_Select = DB.Jump ? ((DB.instr[6:0] == 7'b1100111) ? JUMP_TO_CALCULATED_REGISTER : JUMP_TO_LABEL) :
                           (EB.Branch_taken ? JUMP_TO_LABEL : STEP_FORWARD);

    assign ALUResult_to_Fetch = (DB.Jump && DB.instr[6:0] == 7'b1100111) ? jalr_target : EB.ALUResult;

endmodule
