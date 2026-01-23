import Pkg::*;

module ProgramCounterMux(
    
    input Decode_Bundle    DB,
    input Execute_Bundle   EB,
    input Memory_Bundle    MB,
    input WriteBack_Bundle WB,
    output Fetch_Bundle    FB
);

always_comb begin 
    case (DB.PCNext_Select)
        STEP_FORWARD:                       FB.PCNext = FB.PC4;

        JUMP_TO_CALCULATED_REGISTER:        FB.PCNext = EB.ALUResult;

        JUMP_TO_LABEL:                      FB.PCNext = EB.Target_Address;

        default:                            FB.PCNext = FB.PC4;
    endcase
end
endmodule

module ProgramCounter (
    input  logic                 clk,
    input  logic                 reset,
    input  Decode_Bundle         DB,
    input  Execute_Bundle        EB,
    input  Memory_Bundle         MB,
    input  WriteBack_Bundle      WB,
    output Fetch_Bundle          FB
);

always_ff @ (posedge clk or posedge reset) begin 
    if (reset) begin 
        FB.Address <= 32'b0;
    end

    else begin 
        FB.Address <= FB.PCNext;
    end
end
endmodule

module PCPlus4(
    input  Decode_Bundle    DB,
    input  Execute_Bundle   EB,
    input  Memory_Bundle    MB,
    input  WriteBack_Bundle WB,
    output Fetch_Bundle     FB
);

assign FB.PC4 = FB.Address + 32'h4;

endmodule

module InstructionMemory #(
    parameter Size = 1024
)(  input Decode_Bundle    DB,
    input Execute_Bundle   EB,
    input Memory_Bundle    MB,
    input WriteBack_Bundle WB,
    output Fetch_Bundle    FB
);

logic [31:0] im[Size-1:0];

initial begin
    $readmemh("C:/Users/creat/RV32I/RV32I.srcs/sim_1/new/Program.mem",im);
end

assign FB.instr = im[FB.Address[31:2] % Size];

endmodule