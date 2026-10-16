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
                DUT.WB_Stage.MB.Address,
                DUT.WB_Stage.MB.instr,
                DUT.WB_Stage.MB.RegW,
                DUT.WB_Stage.WD3,
                DUT.WB_Stage.MB.RS1,
                DUT.WB_Stage.MB.RS2,
                DUT.WB_Stage.MB.rd,
                DUT.WB_Stage.MB.Branch_taken,
                DUT.WB_Stage.MB.Jump
            );

            if (DUT.WB_Stage.MB.instr == 32'h00000073 && DUT.WB_Stage.MB.Address >= 32'h80000400) begin
                repeat(5) @(posedge clk);
                $finish;
            end
        end

        $finish;
    end

endmodule
