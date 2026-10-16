module TCORE(

    input logic clk,
    input logic rst,
    
    output logic        S_LITE_AWREADY,
    input  logic [31:0] S_LITE_AWADDR,
    input  logic        S_LITE_AWVALID,
    input  logic [2:0]  S_LITE_AWPROT,
                        
    output logic        S_LITE_WREADY,
    input  logic [3:0]  S_LITE_WSTRB,
    input  logic [31:0] S_LITE_WDATA,
    input  logic        S_LITE_WVALID,
                        
    output logic [1:0]  S_LITE_BRESP,
    output logic        S_LITE_BVALID,
    input  logic        S_LITE_BREADY,
                        
    output logic        S_LITE_ARREADY,
    input  logic [31:0] S_LITE_ARADDR,
    input  logic        S_LITE_ARVALID,
    input  logic [2:0]  S_LITE_ARPROT,
                        
    output logic [31:0] S_LITE_RDATA,
    output logic        S_LITE_RVALID,
    output logic [1:0]  S_LITE_RRESP,
    input  logic        S_LITE_RREADY,

    output logic [31:0] M_FULL_ARADDR,
    output logic        M_FULL_ARVALID,
    input  logic        M_FULL_ARREADY,
    output logic [7:0]  M_FULL_ARLEN,
    output logic [2:0]  M_FULL_ARSIZE,
    output logic [1:0]  M_FULL_ARBURST,
                        
    input  logic [31:0] M_FULL_RDATA,
    input  logic        M_FULL_RVALID,
    output logic        M_FULL_RREADY,
    input  logic        M_FULL_RLAST,
    input  logic [1:0]  M_FULL_RRESP,
                        
    output logic [31:0] M_FULL_AWADDR,
    output logic        M_FULL_AWVALID,
    input  logic        M_FULL_AWREADY,
    output logic [7:0]  M_FULL_AWLEN,
    output logic [2:0]  M_FULL_AWSIZE,
    output logic [1:0]  M_FULL_AWBURST,
                        
    output logic [31:0] M_FULL_WDATA,
    output logic [3:0]  M_FULL_WSTRB,
    output logic        M_FULL_WVALID,
    input  logic        M_FULL_WREADY,
    output logic        M_FULL_WLAST,

    input  logic        M_FULL_BVALID,
    output logic        M_FULL_BREADY,
    input  logic [1:0]  M_FULL_BRESP
    );
    
    
    wire PACKING_ENABLE_WIRE;
    wire SKEW_WIRE;
    wire CLEAR_WIRE;
    wire START_WIRE;
    wire [3:0] ADDR_WIRE;
    wire RE_WIRE;
    wire [15:0] UNPACKED_INPUT_A_WIRE;
    wire [15:0] UNPACKED_INPUT_B_WIRE;
    wire READY_WIRE;
    wire VALID_OUT_CONTROLLER_WIRE;
    wire DONE_WIRE;
    wire [33:0] BUF_DATA_OUT;
    
    wire ACCELERATOR_START_WIRE;
    
    wire [31:0] SOURCE_WIRE;
    wire [31:0] DESTINATION_WIRE;
    wire [31:0] STATUS_WIRE;
    wire [31:0] PERFORMANCE_WIRE;
    
    
    
    DataPath DP (
    
        .CLK(clk),
        
        .RST(rst),
        
        .PACKING_ENABLE(PACKING_ENABLE_WIRE),
        
        .SKEW(SKEW_WIRE),
        
        .CLR_IN(CLEAR_WIRE),
        
        .CLR_ACCUMULATE(CLEAR_WIRE),
        
        .START(START_WIRE),
        
        .ADDR(ADDR_WIRE),
        
        .RE(RE_WIRE),
        
        .UNPACKED_INPUT_A(UNPACKED_INPUT_A_WIRE),
        
        .UNPACKED_INPUT_B(UNPACKED_INPUT_B_WIRE),
        
        .READY(READY_WIRE),
        
        .VALID_OUT_CONTROLLER(VALID_OUT_CONTROLLER_WIRE),
        
        .DONE(DONE_WIRE),
        
        .BUF_DATA_OUT(BUF_DATA_OUT)
    
        );
    
    DMAC DMAC (
    
        .clk(clk),
        
        .rst(rst),
        
        .ACCELERATOR_START_PULSE(ACCELERATOR_START_WIRE),
        
        .SOURCE_ADDRESS(SOURCE_WIRE),
        
        .DESTINATION_ADDRESS(DESTINATION_WIRE),
        
        .STATUS(STATUS_WIRE),
        
        .PERFORMANCE(PERFORMANCE_WIRE),
        
        .DMA_READ_DONE(),
        
        .DMA_WRITE_DONE(),
        
        .DMA_BUSY(),
        
        .BUF_DATA_IN(BUF_DATA_OUT),
        
        .TO_ACCEL_DATA_A(UNPACKED_INPUT_A_WIRE),
        
        .TO_ACCEL_DATA_B(UNPACKED_INPUT_B_WIRE),
        
        .TO_ACCEL_VALID(),
        
        .PACKING_ENABLE(PACKING_ENABLE_WIRE),
        
        .SKEW(SKEW_WIRE),
        
        .START(START_WIRE),
        
        .CLEAR(CLEAR_WIRE),
        
        .RE(RE_WIRE),
        
        .BUF_ADDRESS(ADDR_WIRE),
        
        .READY(READY_WIRE),
        
        .VALID_OUT_CONTROLLER(VALID_OUT_CONTROLLER_WIRE),
        
        .DONE(DONE_WIRE),
        
        .ARADDR     (M_FULL_ARADDR),
           
        .ARVALID    (M_FULL_ARVALID),
          
        .ARREADY    (M_FULL_ARREADY), 
        
        .ARLEN      (M_FULL_ARLEN),
            
        .ARSIZE     (M_FULL_ARSIZE),
           
        .ARBURST    (M_FULL_ARBURST),
        
        .RDATA      (M_FULL_RDATA),
            
        .RVALID     (M_FULL_RVALID), 
          
        .RREADY     (M_FULL_RREADY), 
          
        .RLAST      (M_FULL_RLAST), 
           
        .RRESP      (M_FULL_RRESP),
        
        .AWADDR     (M_FULL_AWADDR), 
          
        .AWVALID    (M_FULL_AWVALID), 
         
        .AWREADY    (M_FULL_AWREADY), 
         
        .AWLEN      (M_FULL_AWLEN), 
           
        .AWSIZE     (M_FULL_AWSIZE), 
          
        .AWBURST    (M_FULL_AWBURST),
        
        .WDATA      (M_FULL_WDATA),  
          
        .WSTRB      (M_FULL_WSTRB), 
           
        .WVALID     (M_FULL_WVALID), 
          
        .WREADY     (M_FULL_WREADY), 
          
        .WLAST      (M_FULL_WLAST),
        
        .BVALID     (M_FULL_BVALID), 
          
        .BREADY     (M_FULL_BREADY), 
          
        .BRESP      (M_FULL_BRESP)
        );
     
    LiteSlave LS(
    
        .clk        (clk),
        
        .rst        (rst),
        
        .AWREADY    (S_LITE_AWREADY),
                 
        .AWADDR     (S_LITE_AWADDR), 
                 
        .AWVALID    (S_LITE_AWVALID),
                 
        .AWPROT     (S_LITE_AWPROT),
              
        .WREADY     (S_LITE_WREADY), 
                 
        .WSTRB      (S_LITE_WSTRB),
                   
        .WDATA      (S_LITE_WDATA), 
                  
        .WVALID     (S_LITE_WVALID),
                
        .BRESP      (S_LITE_BRESP),  
                 
        .BVALID     (S_LITE_BVALID), 
                 
        .BREADY     (S_LITE_BREADY), 
              
        .ARREADY    (S_LITE_ARREADY), 
                
        .ARADDR     (S_LITE_ARADDR),  
                
        .ARVALID    (S_LITE_ARVALID), 
                
        .ARPROT     (S_LITE_ARPROT),   
              
        .RDATA      (S_LITE_RDATA),   
                
        .RVALID     (S_LITE_RVALID),  
                
        .RRESP      (S_LITE_RRESP),  
                 
        .RREADY     (S_LITE_RREADY),   
             
        .STATUS     (STATUS_WIRE),      
            
        .PERFORMANCE(PERFORMANCE_WIRE),  
         
        .SOURCE     (SOURCE_WIRE),      
            
        .DESTINATION(DESTINATION_WIRE),     
           
        .ACCELERATOR_START(ACCELERATOR_START_WIRE)
        );                
    
endmodule
    