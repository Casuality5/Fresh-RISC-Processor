module ResultMux import Pkg::*; (
    input  Memory_Bundle    MB, // Final trunk from Memory
    output WriteBack_Bundle WB  // Trunk going back to the start
);

    always_comb begin 
        // 1. Initialize to clear any floating wires
        WB = '0;
        
        // 2. The Result Mux (The Decision)
        case (MB.ResultSelect)
            RESULT_ALU: WB.Result = MB.ALUResult;
            RESULT_MEM: WB.Result = MB.ReadData; // Ensure this matches your MB struct field
            RESULT_PC:  WB.Result = MB.PC4;
            default:    WB.Result = MB.ALUResult;
        endcase

        // 3. THE CRITICAL STEP: Pass through the write controls
        // Without these, the Register File won't know where to save the Result!
        WB.A3   = MB.A3;   
        WB.RegW = MB.RegW; 
    end

endmodule