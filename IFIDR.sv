module IFIDRegister(
    input logic clk,
    input logic reset,
    input logic [31:0] instr_f,
    input logic [31:0] Address_f,
    input logic [31:0] PC4_f,
    output logic [31:0] instr_d,
    output logic [31:0] Address_d,
    output logic [31:0] PC4_d
);

always_ff @(posedge clk) begin

    if (reset) begin 
        instr_d     <= 0;
        Address_d   <= 0;
        PC4_d       <= 0;
    end else begin
        instr_d     <= instr_f;
        Address_d   <= Address_f;
        PC4_d       <= PC4_f;
end
end
endmodule