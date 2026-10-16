module Core (
    
    input logic clk,
    input logic rst,
    
    input  logic [31:0] S_FULL_AWADDR,
    input  logic [7:0]  S_FULL_AWLEN,
    input  logic [2:0]  S_FULL_AWSIZE,
    input  logic [1:0]  S_FULL_AWBURST,
    input  logic        S_FULL_AWVALID,
    output logic        S_FULL_AWREADY,
                        
    input  logic [31:0] S_FULL_WDATA,
    input  logic [3:0]  S_FULL_WSTRB,
    input  logic        S_FULL_WVALID,
    input  logic        S_FULL_WLAST,
    output logic        S_FULL_WREADY,
                        
    output logic [1:0]  S_FULL_BRESP,
    output logic        S_FULL_BVALID,
    input  logic        S_FULL_BREADY,
                        
    input  logic [31:0] S_FULL_ARADDR,
    input  logic [7:0]  S_FULL_ARLEN,
    input  logic [2:0]  S_FULL_ARSIZE,
    input  logic [1:0]  S_FULL_ARBURST,
    input  logic        S_FULL_ARVALID,
    output logic        S_FULL_ARREADY,
                        
    output logic [31:0] S_FULL_RDATA,
    output logic        S_FULL_RVALID,
    output logic        S_FULL_RLAST,
    output logic [1:0]  S_FULL_RRESP,
    input  logic        S_FULL_RREADY,
    
    input  logic        M_LITE_ARREADY,
    output logic [31:0] M_LITE_ARADDR,
    output logic        M_LITE_ARVALID,
    output logic [2:0]  M_LITE_ARPROT,
                        
    input  logic [31:0] M_LITE_RDATA,
    input  logic        M_LITE_RVALID,
    input  logic [1:0]  M_LITE_RRESP,
    output logic        M_LITE_RREADY,
                        
    input  logic        M_LITE_AWREADY,
    output logic [31:0] M_LITE_AWADDR,
    output logic        M_LITE_AWVALID,
    output logic [2:0]  M_LITE_AWPROT,
                        
    input  logic        M_LITE_WREADY,
    output logic [3:0]  M_LITE_WSTRB,
    output logic [31:0] M_LITE_WDATA,
    output logic        M_LITE_WVALID,
                        
    input  logic [1:0]  M_LITE_BRESP,
    input  logic        M_LITE_BVALID,
    output logic        M_LITE_BREADY,
    
    output logic CONTROL

    );
    
    
    wire [31:0] CONTROL_WIRE;
    wire [31:0] SOURCE_WIRE;
    wire [31:0] DESTINATION_WIRE;
    
    assign CONTROL = CONTROL_WIRE[0];
    
    Top T(
        
        .clk(clk),
        .rst(rst),
        
        .AWADDR     (S_FULL_AWADDR),
        .AWLEN      (S_FULL_AWLEN),
        .AWSIZE     (S_FULL_AWSIZE),
        .AWBURST    (S_FULL_AWBURST),
        .AWVALID    (S_FULL_AWVALID),
        .AWREADY    (S_FULL_AWREADY),
    
        .WDATA      (S_FULL_WDATA),
        .WSTRB      (S_FULL_WSTRB),
        .WVALID     (S_FULL_WVALID),
        .WLAST      (S_FULL_WLAST),
        .WREADY     (S_FULL_WREADY),
        
        .BRESP      (S_FULL_BRESP),
        .BVALID     (S_FULL_BVALID),
        .BREADY     (S_FULL_BREADY),
        
        .ARADDR     (S_FULL_ARADDR),
        .ARLEN      (S_FULL_ARLEN),
        .ARSIZE     (S_FULL_ARSIZE),
        .ARBURST    (S_FULL_ARBURST),
        .ARVALID    (S_FULL_ARVALID),
        .ARREADY    (S_FULL_ARREADY),
        
        .RDATA      (S_FULL_RDATA),
        .RVALID     (S_FULL_RVALID),
        .RLAST      (S_FULL_RLAST),
        .RRESP      (S_FULL_RRESP),
        .RREADY     (S_FULL_RREADY),
        
        .SOURCE_OUT (SOURCE_WIRE),
        .DESTINATION_OUT(DESTINATION_WIRE),
        .CONTROL_OUT(CONTROL_WIRE)
        );
    
    LiteMaster LT(
        
        .clk(clk),
        .rst(rst),
        
        .Control(CONTROL_WIRE),
        .Source(SOURCE_WIRE), 
        .Destination(DESTINATION_WIRE),
        .Status(),
        .Performance(),
        
        .ARREADY    (M_LITE_ARREADY),
        .ARADDR     (M_LITE_ARADDR), 
        .ARVALID    (M_LITE_ARVALID),
        .ARPROT     (M_LITE_ARPROT), 
     
        .RDATA      (M_LITE_RDATA),  
        .RVALID     (M_LITE_RVALID), 
        .RRESP      (M_LITE_RRESP),  
        .RREADY     (M_LITE_RREADY),
        
        .AWREADY    (M_LITE_AWREADY),
        .AWADDR     (M_LITE_AWADDR), 
        .AWVALID    (M_LITE_AWVALID),
        .AWPROT     (M_LITE_AWPROT),
        
        .WREADY     (M_LITE_WREADY), 
        .WSTRB      (M_LITE_WSTRB),  
        .WDATA      (M_LITE_WDATA),  
        .WVALID     (M_LITE_WVALID),
        
        .BRESP      (M_LITE_BRESP),  
        .BVALID     (M_LITE_BVALID), 
        .BREADY     (M_LITE_BREADY)
        );
        

endmodule    