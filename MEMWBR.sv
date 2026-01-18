module MEMWBRegister (
    input logic clk,
    input logic reset,
    input logic [31:0] ALUResult_m,
    input logic [31:0] FinalDataMemoryRead_m,
    input logic [31:0] PC4_m,
    input bundle_decode_t ctrl_m,
    output logic [31:0] ALUResult_w,
    output logic [31:0] FinalDataMemoryRead_w,
    output logic [31:0] PC4_w,
    output bundle_decode_t ctrl_w
);

always_ff @(posedge clk) begin 
    if (reset) begin
        ALUResult_w <= 0;
        FinalDataMemoryRead_w <= 0;
        PC4_w <= 0;
        ctrl_w <= 0;
    end else begin 
        ALUResult_w <= ALUResult_m;
        FinalDataMemoryRead_w <= FinalDataMemoryRead_m;
        PC4_w <= PC4_m;
        ctrl_w <= ctrl_m;
    end
end
endmodule
