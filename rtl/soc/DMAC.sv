module DMAC(
    input logic clk,
    input logic rst,
    
    input logic ACCELERATOR_START_PULSE,
    input logic [31:0] SOURCE_ADDRESS,
    input logic [31:0] DESTINATION_ADDRESS,
    output logic [31:0] PERFORMANCE,
    output logic DMA_READ_DONE,
    output logic DMA_WRITE_DONE,
    output logic [31:0] STATUS,
    
    // STREAMING INTERFACE TO/FROM DATAPATH
    output logic DMA_BUSY,
    input logic [33:0] BUF_DATA_IN,
//    input logic from_accel_valid,
    output logic [15:0] TO_ACCEL_DATA_A,
    output logic [15:0] TO_ACCEL_DATA_B,
    output logic TO_ACCEL_VALID,
//    output logic from_accel_valid,

    // HARDWARE CONTROL WIRES TO DATAPATH EXPOSED AS PORTS
    output logic PACKING_ENABLE,
    output logic SKEW,
    output logic START,
    output logic CLEAR,
    output logic RE,
    output logic [8:0] BUF_ADDRESS,
    input  logic READY,
    input  logic VALID_OUT_CONTROLLER,
    input  logic DONE,    

    // ADDRESS READ (AR) CHANNEL
    output logic [31:0] ARADDR,
    output logic        ARVALID,
    input  logic        ARREADY,
    output logic [7:0]  ARLEN,
    output logic [2:0]  ARSIZE,
    output logic [1:0]  ARBURST,

    // READ DATA (R) CHANNEL
    input  logic [31:0] RDATA,
    input  logic        RVALID,
    output logic        RREADY,
    input  logic        RLAST,
    input  logic [1:0]  RRESP,

    // ADDRESS WRITE (AW) CHANNEL
    output logic [31:0] AWADDR,
    output logic        AWVALID,
    input  logic        AWREADY,
    output logic [7:0]  AWLEN,
    output logic [2:0]  AWSIZE,
    output logic [1:0]  AWBURST,

    // WRITE DATA (W) CHANNEL
    output logic [31:0] WDATA,
    output logic [3:0]  WSTRB,
    output logic        WVALID,
    input  logic        WREADY,
    output logic        WLAST,

    // WRITE RESPONSE (B) CHANNEL
    input  logic        BVALID,
    output logic        BREADY,
    input  logic [1:0]  BRESP
);


typedef enum logic [3:0]{
    DMA_START,
    READ_IDLE,
    READ_BURST,
    START_COMPUTE,
    SKEWING,
    CLEARING,
    WAITING,
    WRITE_IDLE,
    WRITE_BURST,
    WRITE_RESPONSE
   } states;
   
states current_state, next_state;


reg [3:0] Counter;
    

always_ff @(posedge clk or posedge rst) begin

    if (rst) begin
        current_state <= DMA_START;
        Counter <= 0;
        PERFORMANCE <= 0;
    end

    else begin
        current_state <= next_state;
        
        if (current_state != DMA_START) PERFORMANCE <= PERFORMANCE + 1;

        if (current_state == READ_BURST && RREADY && RVALID) begin


            if (RLAST) Counter <= 0;

            else Counter <= Counter + 1;

        end

        if (current_state == WRITE_BURST && WREADY && WVALID) begin

            if (Counter != 15) begin
                Counter <= Counter + 1;
            end

            else begin
                Counter <= 0;
            end
        end
    end
end

always_comb begin

    next_state = current_state;
    RREADY = 0;
    ARADDR = 0;
    ARLEN = 15;
    ARSIZE = 1;
    ARBURST = 2'b01;
    ARVALID = 0;
    PACKING_ENABLE = 0;
    TO_ACCEL_VALID = 0;
    TO_ACCEL_DATA_A = 0;
    TO_ACCEL_DATA_B = 0;
    SKEW = 0;
    START = 0;
    CLEAR = 0;
    AWVALID = 0;
    AWVALID = 0;
    AWLEN = 15;
    AWSIZE = 2;
    AWBURST = 0;
    WVALID = 0;
    WSTRB = 4'b0000;
    WDATA = 0;
    WLAST = 0;
    BREADY = 0;
    BUF_ADDRESS = 0;
    RE = 0;


    case (current_state)



        DMA_START: if (ACCELERATOR_START_PULSE) next_state = READ_IDLE;




        READ_IDLE: begin
            ARADDR = SOURCE_ADDRESS;
            ARLEN  = 15;
            ARSIZE = 2;
            ARBURST = 2'b01;
            ARVALID = 1;

            if (ARVALID && ARREADY) next_state = READ_BURST;
        end

        READ_BURST: begin
            RREADY = 1;
            TO_ACCEL_DATA_A  = RDATA[31:16];
            TO_ACCEL_DATA_B  = RDATA[15:0];
            PACKING_ENABLE = RVALID && RREADY;
            TO_ACCEL_VALID = RVALID && RREADY;

            if (RVALID&&RREADY&&RLAST) begin
                next_state = START_COMPUTE;

            end
        end


        START_COMPUTE: if (READY) next_state = SKEWING;


        SKEWING: begin
            SKEW = 1;
            if (VALID_OUT_CONTROLLER) begin
                START = 1;
                next_state = WAITING;
            end
        end

        WAITING: if (DONE) next_state = CLEARING;

        CLEARING: begin
            CLEAR = 1;
            next_state = WRITE_IDLE;
        end


        WRITE_IDLE: begin
            AWADDR = DESTINATION_ADDRESS;
            AWLEN  = 15;
            AWSIZE = 2;
            AWBURST = 2'b01;
            AWVALID = 1;

            if (AWVALID && AWREADY) next_state = WRITE_BURST;
        end


        WRITE_BURST: begin
            
            WVALID = 1;
            WSTRB  = 4'b1111;
            BUF_ADDRESS = Counter;
            RE = 1;
            WDATA = BUF_DATA_IN[31:0];
            WLAST = (Counter == 4'hf);
            if (WVALID && WREADY && WLAST) next_state = WRITE_RESPONSE;

        end


        WRITE_RESPONSE: begin

            BREADY = 1;

            if (BREADY && BVALID) next_state = DMA_START;
            
        end
    endcase
end

assign  STATUS = (current_state != DMA_START);

endmodule