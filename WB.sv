module ResultMux import Pkg::*;(
    
    input logic [31:0] ALUResult, FinalDataMemoryRead, PC4,
    input result_mux_t ResultSelect,
    output logic [31:0] Result
);

always_comb begin 
    case (ResultSelect)
        RESULT_ALU:      Result = ALUResult;

        RESULT_MEM:      Result = FinalDataMemoryRead;

        RESULT_PC:       Result = PC4;
 
        default:         Result = ALUResult;
    endcase
end
endmodule