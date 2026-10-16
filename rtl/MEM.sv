import Pkg::*;

module Memory # (
    parameter Size = 1024)(
    
    input logic clk,
    input logic rst,

    input Execute_Bundle EB,
    output Memory_Bundle MB,

    input  logic [31:0] AWADDR,
    input  logic [7:0]  AWLEN,
    input  logic [2:0]  AWSIZE,
    input  logic [1:0]  AWBURST,
    input  logic        AWVALID,
    output logic        AWREADY,

    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WVALID,
    input  logic        WLAST,
    output logic        WREADY,

    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,

    input  logic [31:0] ARADDR,
    input  logic [7:0]  ARLEN,
    input  logic [2:0]  ARSIZE,
    input  logic [1:0]  ARBURST,
    input  logic        ARVALID,
    output logic        ARREADY,

    output logic [31:0] RDATA,
    output logic        RVALID,
    output logic        RLAST,
    output logic [1:0]  RRESP,
    input  logic        RREADY,
    
    output logic [31:0] Source_out,
    output logic [31:0] Destination_out,
    output logic [31:0] Control_out
);

    localparam Source_Addr      = 32'h0000_0000;
    localparam Destination_Addr = 32'h0000_0004;
    localparam Control_Addr     = 32'h0000_0008;
    localparam ADDR_WIDTH       = $clog2(Size);

    // =========================================================
    // BRAM — True Dual-Port, Byte-Write Enable
    // Follows Vivado UG901 bytewrite_tdp_ram_rf template exactly:
    //   - Single 32-bit array
    //   - Two always_ff blocks (one per port, same clock)
    //   - Read-FIRST in each block
    //   - For-loop byte enables
    //   - Simple pre-computed enable signals (no complex logic inside)
    //   - No rst inside the BRAM always blocks
    // =========================================================
    (* ram_style = "block" *) logic [31:0] DM [0:Size-1];

    // =========================================================
    // CPU pipeline signals
    // =========================================================
    logic [ADDR_WIDTH-1:0] CPU_ADDR;   // Port A word address
    logic [3:0]            CPU_WE;     // Port A byte write enables (pre-computed)
    logic [31:0]           CPU_DIN;    // Port A write data (aligned)
    logic [31:0]           CPU_DOUT;   // Port A read data (registered)

    assign CPU_ADDR = EB.ALUResult[ADDR_WIDTH+1:2];

    // Byte-enable decode for CPU stores — computed outside BRAM block
    always_comb begin
        CPU_WE = 4'b0000;
        if (EB.WE && !rst) begin
            case (EB.instr[14:12])
                3'b000:  CPU_WE = 4'b0001 << EB.ALUResult[1:0];
                3'b001:  CPU_WE = EB.ALUResult[1] ? 4'b1100 : 4'b0011;
                3'b010:  CPU_WE = 4'b1111;
                default: CPU_WE = 4'b1111;
            endcase
        end
    end

    // Write-data alignment for CPU stores — computed outside BRAM block
    always_comb begin
        case (EB.instr[14:12])
            3'b000:  CPU_DIN = {4{EB.RD2[7:0]}};
            3'b001:  CPU_DIN = {2{EB.RD2[15:0]}};
            default: CPU_DIN = EB.RD2;
        endcase
    end

    // =========================================================
    // AXI FSMs  (state registers, counters, address registers)
    // Must be declared before the Port B signals that use them.
    // =========================================================

    // ---- AXI Read FSM ----------------------------------------
    logic [31:0] ARADDR_REG;
    logic [7:0]  ARLEN_REG;
    logic [1:0]  ARBURST_REG;
    logic [7:0]  BURST_COUNT;

    typedef enum logic { READ_IDLE, READ_BURST } read_state_t;
    read_state_t current_read_state, next_read_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_read_state <= READ_IDLE;
            ARADDR_REG         <= '0;
            ARLEN_REG          <= '0;
            ARBURST_REG        <= '0;
            BURST_COUNT        <= '0;
        end else begin
            current_read_state <= next_read_state;

            if (current_read_state == READ_IDLE && ARVALID && ARREADY) begin
                ARADDR_REG  <= ARADDR;
                ARLEN_REG   <= ARLEN;
                ARBURST_REG <= ARBURST;
                BURST_COUNT <= '0;
            end

            if (current_read_state == READ_BURST && RVALID && RREADY) begin
                if (BURST_COUNT == ARLEN_REG)
                    BURST_COUNT <= '0;
                else begin
                    BURST_COUNT <= BURST_COUNT + 1;
                    if (ARBURST_REG == 2'b01)
                        ARADDR_REG <= ARADDR_REG + 32'd4;
                end
            end
        end
    end

    always_comb begin
        next_read_state = current_read_state;
        ARREADY = 1'b0;
        RVALID  = 1'b0;
        RLAST   = 1'b0;
        RRESP   = 2'b00;
        if (!rst) begin
            case (current_read_state)
                READ_IDLE: begin
                    ARREADY = 1'b1;
                    if (ARVALID && ARREADY) next_read_state = READ_BURST;
                end
                READ_BURST: begin
                    RVALID = 1'b1;
                    RLAST  = (BURST_COUNT == ARLEN_REG);
                    if (RVALID && RREADY && RLAST) next_read_state = READ_IDLE;
                end
                default: next_read_state = READ_IDLE;
            endcase
        end
    end

    // ---- AXI Write FSM ---------------------------------------
    logic [31:0] AWADDR_REG;
    logic [7:0]  AWLEN_REG;
    logic [1:0]  AWBURST_REG;
    logic [7:0]  WRITE_COUNT;

    typedef enum logic [1:0] { WRITE_IDLE, WRITE_DATA, WRITE_RESPONSE } write_state_t;
    write_state_t current_write_state, next_write_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_write_state <= WRITE_IDLE;
            AWADDR_REG          <= '0;
            AWLEN_REG           <= '0;
            AWBURST_REG         <= '0;
            WRITE_COUNT         <= '0;
        end else begin
            current_write_state <= next_write_state;

            if (current_write_state == WRITE_IDLE && AWVALID && AWREADY) begin
                AWADDR_REG  <= AWADDR;
                AWLEN_REG   <= AWLEN;
                AWBURST_REG <= AWBURST;
                WRITE_COUNT <= '0;
            end

            if (current_write_state == WRITE_DATA && WVALID && WREADY) begin
                if (WRITE_COUNT == AWLEN_REG && WLAST)
                    WRITE_COUNT <= '0;
                else begin
                    WRITE_COUNT <= WRITE_COUNT + 1;
                    if (AWBURST_REG == 2'b01)
                        AWADDR_REG <= AWADDR_REG + 32'd4;
                end
            end
        end
    end

    always_comb begin
        next_write_state = current_write_state;
        AWREADY = 1'b0;
        WREADY  = 1'b0;
        BVALID  = 1'b0;
        BRESP   = 2'b00;
        if (!rst) begin
            case (current_write_state)
                WRITE_IDLE: begin
                    AWREADY = 1'b1;
                    if (AWVALID && AWREADY) next_write_state = WRITE_DATA;
                end
                WRITE_DATA: begin
                    WREADY = 1'b1;
                    if (WVALID && WREADY && WRITE_COUNT == AWLEN_REG && WLAST)
                        next_write_state = WRITE_RESPONSE;
                end
                WRITE_RESPONSE: begin
                    BVALID = 1'b1;
                    if (BVALID && BREADY) next_write_state = WRITE_IDLE;
                end
                default: next_write_state = WRITE_IDLE;
            endcase
        end
    end

    // =========================================================
    // AXI Port B signals — pre-computed outside BRAM block
    //
    // Port B uses ONE address (AXI_ADDR) for both read and write.
    // When AXI is writing  : AXI_ADDR = write address (read output ignored)
    // When AXI is reading  : AXI_ADDR = next read address to pre-fetch
    //
    // This gives Port B a single address, satisfying the TDP template.
    // =========================================================
    logic [ADDR_WIDTH-1:0] AXI_ADDR;   // Port B unified address
    logic [3:0]            AXI_WE;     // Port B byte write enables

    // Write enable: active only during AXI write data phase
    assign AXI_WE = ((current_write_state == WRITE_DATA) && WVALID && WREADY)
                    ? WSTRB : 4'b0000;

    // Address mux:
    //   • During a write beat         → write address
    //   • On first-word read handshake → ARADDR (prefetch word 0)
    //   • During burst, each accepted beat → ARADDR_REG + 4 (prefetch next)
    //   • Otherwise                   → hold ARADDR_REG (current burst addr)
    always_comb begin
        if (|AXI_WE)
            AXI_ADDR = AWADDR_REG[ADDR_WIDTH+1:2];
        else if (current_read_state == READ_IDLE && ARVALID && ARREADY)
            AXI_ADDR = ARADDR[ADDR_WIDTH+1:2];
        else if (current_read_state == READ_BURST && RVALID && RREADY && !RLAST)
            AXI_ADDR = (ARADDR_REG + 32'd4) >> 2;
        else
            AXI_ADDR = ARADDR_REG[ADDR_WIDTH+1:2];
    end

    // =========================================================
    // PORT A — CPU  (UG901 bytewrite_tdp_ram_rf, read-first)
    // =========================================================
    always_ff @(posedge clk) begin
        // 1. Read first (read-first mode required by UG901 template)
        CPU_DOUT <= DM[CPU_ADDR];
        // 2. Byte-enable write via for-loop (required by UG901 template)
        for (int i = 0; i < 4; i++) begin
            if (CPU_WE[i])
                DM[CPU_ADDR][i*8 +: 8] <= CPU_DIN[i*8 +: 8];
        end
    end

    // =========================================================
    // PORT B — AXI DMA  (UG901 bytewrite_tdp_ram_rf, read-first)
    // =========================================================
    always_ff @(posedge clk) begin
        // 1. Read first
        RDATA <= DM[AXI_ADDR];
        // 2. Byte-enable write via for-loop
        for (int i = 0; i < 4; i++) begin
            if (AXI_WE[i])
                DM[AXI_ADDR][i*8 +: 8] <= WDATA[i*8 +: 8];
        end
    end

    // =========================================================
    // MB — combinational pipeline bundle
    // =========================================================
    logic [7:0]  BYTE_DATA;
    logic [15:0] HALF_DATA;

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
            2'b00: BYTE_DATA = CPU_DOUT[7:0];
            2'b01: BYTE_DATA = CPU_DOUT[15:8];
            2'b10: BYTE_DATA = CPU_DOUT[23:16];
            2'b11: BYTE_DATA = CPU_DOUT[31:24];
        endcase

        HALF_DATA = EB.ALUResult[1] ? CPU_DOUT[31:16] : CPU_DOUT[15:0];

        case (EB.instr[14:12])
            3'b000:  MB.DataMemoryRead = {{24{BYTE_DATA[7]}}, BYTE_DATA};
            3'b001:  MB.DataMemoryRead = {{16{HALF_DATA[15]}}, HALF_DATA};
            3'b010:  MB.DataMemoryRead = CPU_DOUT;
            3'b100:  MB.DataMemoryRead = {24'b0, BYTE_DATA};
            3'b101:  MB.DataMemoryRead = {16'b0, HALF_DATA};
            default: MB.DataMemoryRead = CPU_DOUT;
        endcase
    end

    // =========================================================
    // MMIO Registered Outputs
    // =========================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            Source_out      <= 32'b0;
            Destination_out <= 32'b0;
            Control_out     <= 32'b0;
        end else if (EB.WE) begin
            if (EB.ALUResult == Source_Addr)      Source_out      <= CPU_DIN;
            if (EB.ALUResult == Destination_Addr) Destination_out <= CPU_DIN;
            if (EB.ALUResult == Control_Addr)     Control_out     <= CPU_DIN;
        end
    end

endmodule