`timescale 1ns / 1ps

module Pilot;

    logic clk = 0;
    logic rst = 1;

    Top DUT(clk, rst);

    always #5 clk = ~clk;

    initial begin
        #5 rst = 0;

        repeat(800) begin
            @(posedge clk);

            $display(
                "PC=%h | INSTR=%h | RegW=%b | WD3=%h | RS1=%d | RS2=%d | RD=%d | Branch=%b | Jump=%b",
                DUT.rm.MB.Address,
                DUT.rm.MB.instr,
                DUT.rm.MB.RegW,
                DUT.rm.WD3,
                DUT.rm.MB.RS1,
                DUT.rm.MB.RS2,
                DUT.rm.MB.rd,
                DUT.rm.MB.Branch_taken,
                DUT.rm.MB.Jump
            );

            if (DUT.rm.MB.instr == 32'h00000073 && DUT.rm.MB.Address >= 32'h80000400) begin
                repeat(5) @(posedge clk);
                $finish;
            end
        end

        $finish;
    end

endmodule
