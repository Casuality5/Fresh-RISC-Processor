module LiteSlave (
    input  logic        clk,
    input  logic        rst,

    output logic        AWREADY,
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    input  logic [2:0]  AWPROT,

    output logic        WREADY,
    input  logic [3:0]  WSTRB,
    input  logic [31:0] WDATA,
    input  logic        WVALID,

    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY,

    output logic        ARREADY,
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    input  logic [2:0]  ARPROT,

    output logic [31:0] RDATA,
    output logic        RVALID,
    output logic [1:0]  RRESP,
    input  logic        RREADY,

    input  logic [31:0] STATUS,
    input  logic [31:0] PERFORMANCE,

    output logic [31:0] SOURCE,
    output logic [31:0] DESTINATION,
    output logic        ACCELERATOR_START
);


localparam ADDR_SOURCE      = 32'h0000_0000;
localparam ADDR_DESTINATION = 32'h0000_0004;
localparam ADDR_CONTROL     = 32'h0000_0008;
localparam ADDR_STATUS      = 32'h0000_000C;
localparam ADDR_PERFORMANCE = 32'h0000_0010;



typedef enum logic [1:0] {

    RECEIVE_WRITE,
    COMMIT_WRITE,
    RESPONSE

} write_states;

write_states current_write_state, next_write_state;


reg AWDONE_HS_REG;
reg WDONE_HS_REG;
reg AWDONE_REG_SEEN;
reg WDONE_REG_SEEN;
reg [31:0] ADDR_REG;
reg [31:0] DATA_REG;

always_ff @(posedge clk or posedge rst) begin

    if (rst) begin
        current_write_state <= RECEIVE_WRITE;
        ADDR_REG <= 0;
        DATA_REG <= 0;
        AWDONE_REG_SEEN <= 0;
        WDONE_REG_SEEN <= 0;
        SOURCE <= 0;
        DESTINATION <= 0;
        ACCELERATOR_START <= 0;
        
    end

    else begin
        current_write_state <= next_write_state;
        ACCELERATOR_START <= 0;
        if (AWDONE_HS_REG) begin
            ADDR_REG <= AWADDR;
            AWDONE_REG_SEEN <= 1;
        end

        if (WDONE_HS_REG) begin
            DATA_REG <= WDATA;
            WDONE_REG_SEEN <= 1;
        end

        if (current_write_state == RESPONSE) begin

            AWDONE_REG_SEEN <= 0;
            WDONE_REG_SEEN <= 0;
        end

        if (current_write_state == COMMIT_WRITE) begin
            case (ADDR_REG)
                ADDR_SOURCE:      SOURCE      <= DATA_REG;
                ADDR_DESTINATION: DESTINATION <= DATA_REG;
                ADDR_CONTROL:     if (DATA_REG == 32'h0000_0005) ACCELERATOR_START <= 1;
            endcase
        end
    end
end



always_comb begin

    next_write_state = current_write_state;
    AWREADY = 0;
    WREADY = 0;
    BVALID = 0;
    AWDONE_HS_REG = 0;
    WDONE_HS_REG = 0;
    BRESP = 0;


    case (current_write_state)

        RECEIVE_WRITE: begin

        AWREADY = 1;
        WREADY  = 1;

        AWDONE_HS_REG = AWVALID && AWREADY;
        WDONE_HS_REG  = WVALID && WREADY;

        if (AWDONE_REG_SEEN && WDONE_REG_SEEN) next_write_state = COMMIT_WRITE;

        end
        
        COMMIT_WRITE: next_write_state = RESPONSE;

        RESPONSE: begin

            BVALID = 1;

            if (BVALID && BREADY) next_write_state = RECEIVE_WRITE;
        end

    endcase
end

reg [31:0] ADDR_REG_READ;

typedef enum logic [1:0] {

    SEND_READ,
    READ_COMMIT,
    READ_RESPONSE

} read_states;

read_states current_read_state, next_read_state;

reg ARDONE_HS_REG;
reg RDONE_HS_REG;


always_ff @(posedge clk or posedge rst) begin

    if (rst) begin
        current_read_state <= SEND_READ;
        ADDR_REG_READ <= 0;
        RDATA <= 0;
    end

    else begin
        current_read_state <= next_read_state;
        if (ARDONE_HS_REG) begin
            ADDR_REG_READ <= ARADDR;
        end
        if (current_read_state == READ_COMMIT) begin
            case (ADDR_REG_READ)
                ADDR_STATUS: RDATA <= STATUS;
                ADDR_PERFORMANCE : RDATA <= PERFORMANCE;
                default: RDATA <= 0;
                endcase
        end
    end
end
always_comb begin
    next_read_state = current_read_state;
    ARREADY = 0;
    RVALID = 0;
    RRESP = 2'b00;
    ARDONE_HS_REG = 0;
    RDONE_HS_REG = 0;
    
        case (current_read_state)

            SEND_READ: begin
                ARREADY = 1;
                ARDONE_HS_REG = ARVALID && ARREADY;
                if (ARDONE_HS_REG) next_read_state = READ_COMMIT;
            end

            READ_COMMIT: next_read_state = READ_RESPONSE;
            
            READ_RESPONSE: begin
                RVALID = 1;
                RDONE_HS_REG = RVALID && RREADY;
                if (RDONE_HS_REG) next_read_state = SEND_READ;
            end
        endcase
end


        
         
endmodule