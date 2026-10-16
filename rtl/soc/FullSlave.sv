module FullSlave #(
    parameter int ADDR_WIDTH = 12
)(
    input  logic        clk,
    input  logic        rst,

    input  logic [63:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    input  logic [7:0]  AWLEN,
    input  logic [2:0]  AWSIZE,
    input  logic [1:0]  AWBURST,

    input  logic [63:0] WDATA,
    input  logic [7:0]  WSTRB,
    input  logic        WVALID,
    output logic        WREADY,
    input  logic        WLAST,

    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,

    input  logic [63:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    input  logic [7:0]  ARLEN,
    input  logic [2:0]  ARSIZE,
    input  logic [1:0]  ARBURST,

    output logic [63:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic        RLAST,
    output logic [1:0]  RRESP,

    output logic                  dma_mem_we,
    output logic [ADDR_WIDTH-1:0] dma_mem_waddr,
    output logic [63:0]           dma_mem_wdata,
    output logic [7:0]            dma_mem_wstrb,

    output logic                  dma_mem_re,
    output logic [ADDR_WIDTH-1:0] dma_mem_raddr,
    input  logic [63:0]           dma_mem_rdata
);

    typedef enum logic [1:0] {
        WRITE_IDLE,
        WRITE_BURST,
        WRITE_RESPONSE
    } write_states;

    write_states current_write_state, next_write_state;

    logic [ADDR_WIDTH-1:0] write_addr_reg;
    logic [7:0] write_len_reg;

    typedef enum logic {
        READ_IDLE,
        READ_BURST
    } read_states;

    read_states current_read_state, next_read_state;

    logic [ADDR_WIDTH-1:0] read_addr_reg;
    logic [7:0] read_len_reg;

    assign BRESP = 2'b00;
    assign RRESP = 2'b00;
    assign RDATA = dma_mem_rdata;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_write_state <= WRITE_IDLE;
            write_addr_reg      <= '0;
            write_len_reg       <= '0;

            current_read_state  <= READ_IDLE;
            read_addr_reg       <= '0;
            read_len_reg        <= '0;
        end
        else begin
            current_write_state <= next_write_state;
            current_read_state  <= next_read_state;

            if (current_write_state == WRITE_IDLE &&
                AWVALID && AWREADY) begin
                write_addr_reg <= AWADDR[ADDR_WIDTH+2:3];
                write_len_reg  <= AWLEN;
            end

            if (current_write_state == WRITE_BURST &&
                WVALID && WREADY) begin
                write_addr_reg <= write_addr_reg + 1'b1;

                if (!(WLAST || write_len_reg == 8'd0))
                    write_len_reg <= write_len_reg - 1'b1;
            end

            if (current_read_state == READ_IDLE &&
                ARVALID && ARREADY) begin
                read_addr_reg <= ARADDR[ADDR_WIDTH+2:3];
                read_len_reg  <= ARLEN;
            end

            if (current_read_state == READ_BURST &&
                RVALID && RREADY &&
                read_len_reg != 8'd0) begin
                read_addr_reg <= read_addr_reg + 1'b1;
                read_len_reg  <= read_len_reg - 1'b1;
            end
        end
    end

    always_comb begin
        next_write_state = current_write_state;

        AWREADY       = 1'b0;
        WREADY        = 1'b0;
        BVALID        = 1'b0;
        dma_mem_we    = 1'b0;
        dma_mem_waddr = write_addr_reg;
        dma_mem_wdata = WDATA;
        dma_mem_wstrb = WSTRB;

        if (!rst) begin
            case (current_write_state)
                WRITE_IDLE: begin
                    AWREADY = 1'b1;

                    if (AWVALID && AWREADY)
                        next_write_state = WRITE_BURST;
                end

                WRITE_BURST: begin
                    WREADY = 1'b1;

                    if (WVALID && WREADY) begin
                        dma_mem_we = 1'b1;

                        if (WLAST || write_len_reg == 8'd0)
                            next_write_state = WRITE_RESPONSE;
                    end
                end

                WRITE_RESPONSE: begin
                    BVALID = 1'b1;

                    if (BVALID && BREADY)
                        next_write_state = WRITE_IDLE;
                end

                default: begin
                    next_write_state = WRITE_IDLE;
                end
            endcase
        end
    end

    always_comb begin
        next_read_state = current_read_state;

        ARREADY       = 1'b0;
        RVALID        = 1'b0;
        RLAST         = 1'b0;
        dma_mem_re    = 1'b0;
        dma_mem_raddr = read_addr_reg;

        if (!rst) begin
            case (current_read_state)
                READ_IDLE: begin
                    ARREADY = 1'b1;

                    if (ARVALID && ARREADY) begin
                        dma_mem_re    = 1'b1;
                        dma_mem_raddr = ARADDR[ADDR_WIDTH+2:3];
                        next_read_state = READ_BURST;
                    end
                end

                READ_BURST: begin
                    RVALID = 1'b1;
                    RLAST  = (read_len_reg == 8'd0);

                    if (RVALID && RREADY) begin
                        if (read_len_reg == 8'd0) begin
                            next_read_state = READ_IDLE;
                        end
                        else begin
                            dma_mem_re    = 1'b1;
                            dma_mem_raddr = read_addr_reg + 1'b1;
                        end
                    end
                end

                default: begin
                    next_read_state = READ_IDLE;
                end
            endcase
        end
    end

endmodule