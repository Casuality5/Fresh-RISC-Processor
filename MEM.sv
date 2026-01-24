import Pkg::*;

module Memory #(parameter Size = 1024) (
    input  logic           clk, reset,
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
        if (EB.MemW && !reset) begin
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