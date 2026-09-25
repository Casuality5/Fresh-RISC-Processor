`timescale 1ns / 1ps

import Pkg::*;

module Memory #(
    parameter Size = 4096
)(
    input  Execute_Bundle EB,
    output Memory_Bundle MB,
    input  logic clk,
    input  logic rst
);

    localparam AddrWidth = $clog2(Size);
    logic [AddrWidth-1:0] addr;
    assign addr = EB.ALUResult[AddrWidth+1:2];

    // 4 Byte Lanes for True FPGA Block RAM Inference
    (* ram_style = "block" *) logic [7:0] dm0 [0:Size-1];
    (* ram_style = "block" *) logic [7:0] dm1 [0:Size-1];
    (* ram_style = "block" *) logic [7:0] dm2 [0:Size-1];
    (* ram_style = "block" *) logic [7:0] dm3 [0:Size-1];

    // 1. SYNCHRONOUS BRAM READ & BYTE-WRITE ENABLES
    logic [31:0] DataMemoryRead;
    logic [3:0]  we_bytes;

    // Byte Enable Decoder
    always_comb begin
        we_bytes = 4'b0000;
        if (EB.WE) begin
            case (EB.instr[14:12])
                3'b000:  we_bytes = 4'b0001 << EB.ALUResult[1:0];         // SB
                3'b001:  we_bytes = EB.ALUResult[1] ? 4'b1100 : 4'b0011; // SH
                3'b010:  we_bytes = 4'b1111;                             // SW
                default: we_bytes = 4'b1111;
            endcase
        end
    end

    // Clocked Read & Write (Matches Hardware BRAM Primitives)
    always_ff @(posedge clk) begin
        // Read (Synchronous)
        DataMemoryRead[7:0]   <= dm0[addr];
        DataMemoryRead[15:8]  <= dm1[addr];
        DataMemoryRead[23:16] <= dm2[addr];
        DataMemoryRead[31:24] <= dm3[addr];

        // Byte Writes
        if (we_bytes[0]) dm0[addr] <= (EB.instr[14:12] == 3'b000) ? EB.RD2[7:0]   : EB.RD2[7:0];
        if (we_bytes[1]) dm1[addr] <= (EB.instr[14:12] == 3'b000) ? EB.RD2[7:0]   : EB.RD2[15:8];
        if (we_bytes[2]) dm2[addr] <= (EB.instr[14:12] == 3'b000) ? EB.RD2[7:0]   : EB.RD2[23:16];
        if (we_bytes[3]) dm3[addr] <= (EB.instr[14:12] == 3'b000) ? EB.RD2[7:0]   : EB.RD2[31:24];
    end

    // 2. COMBINATIONAL OUTPUT SIGNALS TO WB STAGE
    logic [7:0]  Byte_Data;
    logic [15:0] Half_Data;

    always_comb begin
        MB.WE             = EB.WE;
        MB.Branch_taken   = EB.Branch_taken;
        MB.Jump           = EB.Jump;
        MB.instr          = EB.instr;
        MB.WD             = EB.RD2;
        MB.RegW           = EB.RegW;
        MB.PC4            = EB.PC4;
        MB.rd             = EB.rd;
        MB.ALUResult      = EB.ALUResult;
        MB.Address        = EB.Address;
        MB.Target_Address = EB.Target_Address;
        MB.ResultSelect   = EB.ResultSelect;
        MB.RS1            = EB.RS1;
        MB.RS2            = EB.RS2;

        case (EB.ALUResult[1:0])
            2'b00: Byte_Data = DataMemoryRead[7:0];
            2'b01: Byte_Data = DataMemoryRead[15:8];
            2'b10: Byte_Data = DataMemoryRead[23:16];
            2'b11: Byte_Data = DataMemoryRead[31:24];
        endcase

        Half_Data = EB.ALUResult[1] ? DataMemoryRead[31:16] : DataMemoryRead[15:0];

        case (EB.instr[14:12])
            3'b000:  MB.FinalDataMemoryRead = {{24{Byte_Data[7]}}, Byte_Data}; 
            3'b001:  MB.FinalDataMemoryRead = {{16{Half_Data[15]}}, Half_Data}; 
            3'b010:  MB.FinalDataMemoryRead = DataMemoryRead;                   
            3'b100:  MB.FinalDataMemoryRead = {24'b0, Byte_Data};               
            3'b101:  MB.FinalDataMemoryRead = {16'b0, Half_Data};               
            default: MB.FinalDataMemoryRead = DataMemoryRead;
        endcase
    end

endmodule
