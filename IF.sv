module ProgramCounterMux(
    
    input logic     [31:0]      PC4,
    input logic     [31:0]      ALUResult,
    input logic     [31:0]      Target_Address,
    input Pkg::pc_next_select_t PCNext_select,                     
    output logic    [31:0]      PCNext
);

always_comb begin 
    case (PCNext_select)
        STEP_FORWARD:                       PCNext = PC4;

        JUMP_TO_CALCULATED_REGISTER:        PCNext = ALUResult;

        JUMP_TO_LABEL:                      PCNext = Target_Address;

        default:                            PCNext = PC4;
    endcase
end
endmodule

module ProgramCounter(
    input logic                 clk,
    input logic                 reset,
    input logic     [31:0]      PCNext,
    output logic    [31:0]      Address
);

always_ff @ (posedge clk or posedge reset) begin 
    if (reset) begin 
        Address <= 32'b0;
    end

    else begin 
        Address <= PCNext;
    end
end
endmodule

module PCPlus4(
    input logic [31:0] Address,
    output logic [31:0] PC4
);

assign PC4 = Address + 32'h4;

endmodule

module InstructionMemory #(
    parameter Size = 1024
)(
    input logic [31:0] Address,
    output logic [31:0] instr
);

logic [31:0] im[Size-1:0];

initial begin
    $readmemh("C:/Users/creat/RV32I/RV32I.srcs/sim_1/new/Program.mem",im);
end

assign instr = im[Address[31:2] % Size];

endmodule