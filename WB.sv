module ResultMux import Pkg::*; (
    input  Memory_Bundle    MB,
    output logic WE3,
    output logic [4:0] A3,
    output logic [31:0] WD3
);

    always_comb begin 
        WD3 = MB.ALUResult;
        case (MB.ResultSelect)
            RESULT_ALU: WD3 = MB.ALUResult;
            RESULT_MEM: WD3 = MB.FinalDataMemoryRead;
            RESULT_PC:  WD3 = MB.PC4;
            default:    WD3 = MB.ALUResult;
        endcase
           
        
    end
assign A3   = MB.rd;
assign WE3 = MB.RegW;

endmodule