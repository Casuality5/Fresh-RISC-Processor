import Pkg::*;

module Fetch #(
    parameter Size = 1024
)(
    input logic            clk,
    input logic            rst,
    input Execute_Bundle   EB,
    output Fetch_Bundle    FB
);

logic [31:0] pc_next;
logic [31:0] address;
logic [31:0] pc4;
logic [31:0] instr_out;
logic [31:0] im[Size-1:0];

assign pc4 = address + 32'h4;

always_comb begin 
    case (EB.PCNext_Select)
        STEP_FORWARD:                       pc_next = pc4;

        JUMP_TO_CALCULATED_REGISTER:        pc_next = EB.ALUResult;

        JUMP_TO_LABEL:                      pc_next = EB.Target_Address;

        default:                            pc_next = pc4;
    endcase
end


always_ff @ (posedge clk or posedge rst) begin 
    if (rst) begin 
        address <= 32'b0;
    end

    else begin 
        address <= pc_next;
    end
end

initial begin
    $readmemh("C:/Users/creat/RV32I/RV32I.srcs/sim_1/new/Program.mem",im);
end

assign instr_out = im[address[31:2] % Size];



assign FB.PCNext = pc_next;
assign FB.Address = address;
assign FB.PC4 = pc4;
assign FB.instr = instr_out;
endmodule