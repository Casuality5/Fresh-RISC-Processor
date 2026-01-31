import Pkg::*;

module Fetch #(
    parameter Size = 512
)(
    input logic            clk,
    input logic            rst,
    input PC_Next_Select_Case PCNext_Select,
    input logic [31:0] Target_Address,
    input logic [31:0] ALUResult_to_Fetch,
    input Execute_Bundle EB,
    output Fetch_Bundle    FB
);

//logic [31:0] pc_next;
logic [31:0] instr_out;
logic [31:0] im[Size-1:0];

assign FB.PC4 = FB.Address + 32'h4;

always_comb begin 
    FB.PCNext = '0;
    case (PCNext_Select)
        STEP_FORWARD:                       FB.PCNext = FB.PC4;

        JUMP_TO_CALCULATED_REGISTER:        FB.PCNext = ALUResult_to_Fetch;

        JUMP_TO_LABEL:                      FB.PCNext = Target_Address;
    endcase
end


always_ff @ (posedge clk or posedge rst) begin 
    if (rst) begin 
        FB.Address <= 32'b0;
    end

    else begin 
        FB.Address <= FB.PCNext;
    end
end

initial begin
    $readmemh("Program.mem",im);
end

assign instr_out = im[FB.Address[31:2] % Size];


//assign FB.PCNext = pc_next;
//assign FB.Address = address;
//assign FB.PC4 = pc4;
assign FB.instr = instr_out;
endmodule