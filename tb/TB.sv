`timescale 1ns / 1ps

module tb import Pkg::*; ();
    logic clk;
    logic rst;
    logic WE3_to_testbench;
    logic [31:0] WD3_to_testbench;
    logic [4:0] A3_to_testbench;
    Memory_Bundle wb_in_to_testbench;
    logic branch_taken_to_testbench;
    logic regwrite_from_decode_to_testbench;
    

    // Instantiate your Core
    Top dut (
        .clk(clk),
        .rst(rst),
        .wb_in_to_testbench(wb_in_to_testbench),
        .WE3_to_testbench(WE3_to_testbench),
        .WD3_to_testbench(WD3_to_testbench),
        .A3_to_testbench(A3_to_testbench),
        .branch_taken_to_testbench(branch_taken_to_testbench),
        .regwrite_from_decode_to_testbench(regwrite_from_decode_to_testbench)
    );

    // 1. Generate Clock (100MHz)
    always #5 clk = ~clk;
    
    integer fd;
    // 2. The Test Sequence
    initial begin
        // Initialize
        fd = $fopen("C:/Users/creat/Desktop/dut_trace.log", "w");

        $display("File opened");
        if (fd == 0) begin
            $display("ERROR: cannot open file");
            $finish;
        end
        clk = 0;
        rst = 1;
        
        // Hold reset for a few cycles
        #5;
        rst = 0;

        // Run for enough time to see the instructions pass through all 5 stages
        #50000;
        $fclose(fd);
        $display("File closed");
        $display("Simulation Finished. Check the Waveform!");
        $finish;
    end
    always @(posedge clk) begin
    if (!rst) begin
        case (wb_in_to_testbench.instr[6:0])

            7'b0100011: begin
                case (wb_in_to_testbench.instr[14:12])
                    3'b000: $fwrite(fd, "%08h mem %08h %02h\n",   // SB → 2 digits
                            wb_in_to_testbench.Address,
                            wb_in_to_testbench.ALUResult,
                            wb_in_to_testbench.WD[7:0]);

                    3'b001: $fwrite(fd, "%08h mem %08h %04h\n",   // SH → 4 digits
                            wb_in_to_testbench.Address,
                            wb_in_to_testbench.ALUResult,
                            wb_in_to_testbench.WD[15:0]);

                    3'b010: $fwrite(fd, "%08h mem %08h %08h\n",   // SW → 8 digits
                            wb_in_to_testbench.Address,
                            wb_in_to_testbench.ALUResult,
                            wb_in_to_testbench.WD);
                endcase
            end
            
            7'b0000011:
                $fwrite(fd, "%08h %02d %08h mem %08h\n",
                    wb_in_to_testbench.Address,
                    wb_in_to_testbench.rd,
                    WD3_to_testbench,
                    wb_in_to_testbench.ALUResult);




            7'b0110011,   // R-Type
            7'b0010011,   // I-ALU
            7'b1100011,   // Branch
            7'b1101111,   // JAL
            7'b1100111,   // JALR
            7'b0110111,   // LUI
            7'b0010111:   // AUIPC

                if ((wb_in_to_testbench.instr == 32'h0000013)||(wb_in_to_testbench.instr[6:0] == 7'b1100011)||(A3_to_testbench == '0))
                    $fwrite(fd, "%08h\n",wb_in_to_testbench.Address);
                else
                    $fwrite(fd, "%08h %02d %08h\n",
                    wb_in_to_testbench.Address,
                    (wb_in_to_testbench.RegW ? wb_in_to_testbench.rd : 5'd0),
                    (wb_in_to_testbench.RegW ? WD3_to_testbench : 32'b0));

            default: begin end
        endcase
    end
end
endmodule
