`timescale 1ns / 1ps

module tb();
    logic clk;
    logic rst;

    // Instantiate your Core
    Top dut (
        .clk(clk),
        .rst(rst)
    );

    // 1. Generate Clock (100MHz)
    always #5 clk = ~clk;

    // 2. The Test Sequence
    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        
        // Hold reset for a few cycles
        #20;
        rst = 0;

        // Run for enough time to see the instructions pass through all 5 stages
        #200;
        $display("Simulation Finished. Check the Waveform!");
    end
endmodule