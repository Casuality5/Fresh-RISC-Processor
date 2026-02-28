`timescale 1ns / 1ps

module tb import Pkg::*; ();
    logic clk;
    logic rst;
    logic WE3_to_testbench;
    logic [31:0] WD3_to_testbench;
    logic [4:0] A3_to_testbench;
    Memory_Bundle wb_in_to_testbench;
    

    // Instantiate your Core
    Top dut (
        .clk(clk),
        .rst(rst),
        .wb_in_to_testbench(wb_in_to_testbench),
        .WE3_to_testbench(WE3_to_testbench),
        .WD3_to_testbench(WD3_to_testbench),
        .A3_to_testbench(A3_to_testbench)
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
        #20;
        rst = 0;

        // Run for enough time to see the instructions pass through all 5 stages
        #200;
        $fclose(fd);
        $display("File closed");
        $display("Simulation Finished. Check the Waveform!");
        $finish;
    end
    always @(posedge clk) begin
        if (!rst) begin
            if (WE3_to_testbench && A3_to_testbench !=0) begin
                $fwrite(fd, "%08h %02d %08h\n", wb_in_to_testbench.PC4-4, A3_to_testbench, WD3_to_testbench);
               end
         end
    end
endmodule