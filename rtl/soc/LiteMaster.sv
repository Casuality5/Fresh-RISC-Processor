module LiteMaster (
    input  logic        clk,
    input  logic        rst,
    
    // Processor register inputs
    input  logic [31:0] Control,
    input  logic [31:0] Source,
    input  logic [31:0] Destination,
    output logic  [31:0] Status,
    output logic  [31:0] Performance,

    // READ ADDRESS CHANNEL
    input  logic        ARREADY,
    output logic [31:0] ARADDR,
    output logic        ARVALID,
    output logic [2:0]  ARPROT,

    // READ DATA CHANNEL
    input  logic [31:0] RDATA,
    input  logic        RVALID,
    input  logic [1:0]  RRESP,
    output logic        RREADY,

    // WRITE ADDRESS CHANNEL
    input  logic        AWREADY,
    output logic [31:0] AWADDR,
    output logic        AWVALID,
    output logic [2:0]  AWPROT,

    // WRITE DATA CHANNEL
    input  logic        WREADY,
    output logic [3:0]  WSTRB,
    output logic [31:0] WDATA,
    output logic        WVALID,

    // WRITE RESPONSE CHANNEL
    input  logic [1:0]  BRESP,
    input  logic        BVALID,
    output logic        BREADY
);
    
    localparam ADDR_SOURCE      = 32'h0000_0000;
    localparam ADDR_DESTINATION = 32'h0000_0004;
    localparam ADDR_CONTROL     = 32'h0000_0008;
    localparam ADDR_STATUS      = 32'h0000_000C;
    localparam ADDR_PERFORMANCE = 32'h0000_0010;


    logic start_cmd_d, read_cmd_d;

    wire start_cmd  = (Control == 32'd5);
    wire read_cmd   = (Control == 32'd10);
    
    wire start_pulse = start_cmd && !start_cmd_d;
    wire read_pulse  = read_cmd  && !read_cmd_d;
        
    reg AWDONE_REG;
    reg WDONE_REG;
    reg AWDONE;
    reg WDONE;
    
    reg ARDONE_REG;
    reg RDONE_REG;
    reg ARDONE;
    reg RDONE;
    
    
    typedef enum logic [3:0] {
        WRITE_IDLE,
        SETUP_WRITE_SOURCE,
        WRITE_SOURCE,
        RESPONSE_SOURCE,
        SETUP_WRITE_DESTINATION,
        WRITE_DESTINATION,
        RESPONSE_DESTINATION,
        SETUP_WRITE_CONTROL,
        WRITE_CONTROL,
        RESPONSE_CONTROL
    } write_states;
    
    write_states current_write_state, next_write_state;
    
    always_ff @(posedge clk or posedge rst) begin : WRITE_FSM_CONTROL;
        if (rst) begin
            current_write_state <= WRITE_IDLE;
            AWDONE_REG <= 0;
            WDONE_REG <= 0;
            start_cmd_d <= 0;
            read_cmd_d <= 0;
        end
    
        else begin
            current_write_state <= next_write_state;
            start_cmd_d <= start_cmd;
            read_cmd_d <= read_cmd;
            if (AWDONE) AWDONE_REG <= 1;
            if (WDONE) WDONE_REG <= 1;
            if (current_write_state == SETUP_WRITE_CONTROL || current_write_state == SETUP_WRITE_SOURCE || current_write_state == SETUP_WRITE_DESTINATION) begin
                AWDONE_REG <= 0;
                WDONE_REG <= 0;
            end
        end
    end
    

    
    always_comb begin : WRITE_FSM;
        next_write_state = current_write_state;
        AWADDR     = 32'b0;
        WDATA      = 32'b0;
        AWVALID    = 1'b0;
        WVALID     = 1'b0;
        AWPROT     = 3'b000;
        WSTRB      = 4'b1111;
        BREADY     = 1'b0;
        WDONE      = 1'b0;
        AWDONE     = 1'b0;

        case (current_write_state) 
        
            WRITE_IDLE: if (start_pulse) next_write_state = SETUP_WRITE_SOURCE;
            
            
        
            SETUP_WRITE_SOURCE: begin
                AWDONE = 0;
                WDONE  = 0;
                AWVALID = 0;
                WVALID = 0;
                next_write_state = WRITE_SOURCE;
            end
            
            WRITE_SOURCE: begin
                AWVALID = 1;
                WVALID = 1;
                WDATA = Source;
                AWADDR = ADDR_SOURCE;
                if (AWDONE_REG) AWVALID = 0;
                if (WDONE_REG) WVALID = 0;
                AWDONE = AWVALID && AWREADY;
                WDONE  = WVALID && WREADY;
                if (AWDONE_REG && WDONE_REG) next_write_state = RESPONSE_SOURCE;
            end
        
            RESPONSE_SOURCE: begin
                BREADY = 1;
                if (BVALID && BREADY) begin
                    next_write_state = SETUP_WRITE_DESTINATION;
                end
            end
        
            SETUP_WRITE_DESTINATION: begin
                AWDONE = 0;
                WDONE  = 0;
                AWVALID = 0;
                WVALID = 0;
                next_write_state = WRITE_DESTINATION;
            end
            
            WRITE_DESTINATION: begin
                AWVALID = 1;
                WVALID = 1;
                WDATA = Destination;
                AWADDR = ADDR_DESTINATION;
                if (AWDONE_REG) AWVALID = 0;
                if (WDONE_REG) WVALID = 0;
                AWDONE = AWVALID && AWREADY;
                WDONE  = WVALID && WREADY;
                if (AWDONE_REG && WDONE_REG) next_write_state = RESPONSE_DESTINATION;
            end
        
            RESPONSE_DESTINATION: begin
                BREADY = 1;
                if (BVALID && BREADY) begin
                    next_write_state = SETUP_WRITE_CONTROL;
                end
            end
        
            SETUP_WRITE_CONTROL: begin
                AWDONE = 0;
                WDONE  = 0;
                AWVALID = 0;
                WVALID = 0;
                next_write_state = WRITE_CONTROL;
            end
            
            WRITE_CONTROL: begin
                AWVALID = 1;
                WVALID = 1;
                WDATA = Control;
                AWADDR = ADDR_CONTROL;
                if (AWDONE_REG) AWVALID = 0;
                if (WDONE_REG) WVALID = 0;
                AWDONE = AWVALID && AWREADY;
                WDONE  = WVALID && WREADY;
                if (AWDONE_REG && WDONE_REG) next_write_state = RESPONSE_CONTROL;
            end
        
            RESPONSE_CONTROL: begin
                BREADY = 1;
                if (BVALID && BREADY) begin 
                    next_write_state = WRITE_IDLE;
                end
            end
        endcase
    end
    
    
    
    
    typedef enum logic [2:0]{
           
           READ_IDLE,
           
           SETUP_READ_STATUS,
           
           READ_STATUS,
           
           SETUP_READ_PERFORMANCE,
           
           READ_PERFORMANCE
           
    }read_states;
    
    read_states current_read_state, next_read_state;
    
    always_ff @(posedge clk or posedge rst) begin : READ_FSM_CONTROL
        
        if (rst) begin
            current_read_state <= READ_IDLE;
            ARDONE_REG <= 0;
            RDONE_REG  <= 0;
            Status <= 0;
            Performance <= 0;
        end
        
        else begin
            current_read_state <= next_read_state;
            if (ARDONE) ARDONE_REG <= 1;
            if (RDONE) begin
                RDONE_REG   <= 1;
                if (current_read_state == READ_STATUS) Status <= RDATA;
                if (current_read_state == READ_PERFORMANCE) Performance <= RDATA;
            end
            if (current_read_state == SETUP_READ_STATUS || current_read_state == SETUP_READ_PERFORMANCE) begin
                RDONE_REG <= 0;
                ARDONE_REG <= 0;
            end
        end
    end
    
    
    always_comb begin : READ_FSM
        next_read_state = current_read_state;
        ARADDR  = 32'b0;
        ARVALID = 1'b0;
        ARPROT  = 3'b000;
        RREADY  = 1'b0;
        RDONE   = 1'b0;
        ARDONE  = 1'b0;
    
        case(current_read_state)
        
            READ_IDLE: if (read_pulse) next_read_state = SETUP_READ_STATUS;
            
            SETUP_READ_STATUS: begin
                RDONE = 0;
                ARDONE = 0;
                RREADY = 0;
                ARVALID = 0;
                next_read_state = READ_STATUS;
            end
            
            READ_STATUS: begin
                
                RREADY = 1;
                ARVALID = 1;
                ARADDR = ADDR_STATUS;
                if (RDONE_REG) RREADY = 0;
                if (ARDONE_REG) ARVALID = 0;
                RDONE = RVALID && RREADY;
                ARDONE = ARVALID && ARREADY;
                if (RDONE_REG && ARDONE_REG) next_read_state = SETUP_READ_PERFORMANCE;
           end
           
            SETUP_READ_PERFORMANCE: begin
                RDONE = 0;
                ARDONE = 0;
                RREADY = 0;
                ARVALID = 0;
                next_read_state = READ_PERFORMANCE;
            end
            
            READ_PERFORMANCE: begin
                
                RREADY = 1;
                ARVALID = 1;
                ARADDR = ADDR_PERFORMANCE;
                if (RDONE_REG) RREADY = 0;
                if (ARDONE_REG) ARVALID = 0;
                RDONE = RREADY && RVALID;
                ARDONE = ARVALID && ARREADY;
                if (RDONE_REG && ARDONE_REG) next_read_state = READ_IDLE;
           end
        endcase
    end
endmodule