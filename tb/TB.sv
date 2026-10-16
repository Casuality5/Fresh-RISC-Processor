`timescale 1ns / 1ps

import Pkg::*;

module TB;
    logic clk;
    logic rst;

    // Instantiate Top DUT
    Top DUT (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    integer fd;
    integer debug_fd;

    initial begin
        fd = $fopen("dut_trace.log", "w");
        debug_fd = $fopen("my_trace.log", "w");

        $display("==================================================");
        $display("   STARTING RISC-V + TCORE ACCELERATOR SIMULATION ");
        $display("==================================================");

        // Populate Matrix A (all 1s) in Data Memory at Source 0x100 (Row 32-35)
        for (int r = 32; r < 36; r++) begin
            DUT.DM.dm0[r] = 8'h01; DUT.DM.dm1[r] = 8'h00; // 1
            DUT.DM.dm2[r] = 8'h01; DUT.DM.dm3[r] = 8'h00; // 1
            DUT.DM.dm4[r] = 8'h01; DUT.DM.dm5[r] = 8'h00; // 1
            DUT.DM.dm6[r] = 8'h01; DUT.DM.dm7[r] = 8'h00; // 1
        end

        // Populate Matrix B (all 2s) in Data Memory at Source+64 0x140 (Row 40-43)
        for (int r = 40; r < 44; r++) begin
            DUT.DM.dm0[r] = 8'h02; DUT.DM.dm1[r] = 8'h00; // 2
            DUT.DM.dm2[r] = 8'h02; DUT.DM.dm3[r] = 8'h00; // 2
            DUT.DM.dm4[r] = 8'h02; DUT.DM.dm5[r] = 8'h00; // 2
            DUT.DM.dm6[r] = 8'h02; DUT.DM.dm7[r] = 8'h00; // 2
        end

        clk = 0;
        rst = 1;

        #20;
        rst = 0;
        $display("[TB] Reset released. CPU executing MMIO program from Program.mem...");

        // Wait until DMA completes writing back to destination 0x400
        fork
            begin
                wait(DUT.TCORE.dmac.dma_write_done == 1'b1);
                $display("\n==================================================");
                $display("   TCORE ACCELERATOR COMPUTATION COMPLETE!        ");
                $display("==================================================");

                #100;
                $display("\n[TB] Verification of Output Matrix at Destination 0x400:");
                for (int i = 0; i < 16; i++) begin
                    int row_idx = 128 + i; // 0x400 >> 3 = 128
                    logic signed [63:0] val;
                    val = {DUT.DM.dm7[row_idx], DUT.DM.dm6[row_idx], DUT.DM.dm5[row_idx], DUT.DM.dm4[row_idx],
                           DUT.DM.dm3[row_idx], DUT.DM.dm2[row_idx], DUT.DM.dm1[row_idx], DUT.DM.dm0[row_idx]};
                    $display("   Result Element [%0d] at Address 0x%03h = %0d (Hex: 0x%016h)", i, (128+i)<<3, val, val);
                end
            end
            begin
                #100000;
                $display("[TB] Timeout reached after 100us!");
            end
        join_any

        if (fd != 0) $fclose(fd);
        if (debug_fd != 0) $fclose(debug_fd);
        $display("\nSimulation Finished Successfully!");
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) begin
            case (TB.DUT.memwb.q.instr[6:0])
                7'b0100011: begin
                    case (TB.DUT.memwb.q.instr[14:12])
                        3'b000: $fwrite(fd, "%08h mem %08h %02h\n",
                                TB.DUT.memwb.q.Address,
                                TB.DUT.memwb.q.ALUResult,
                                TB.DUT.memwb.q.WD[7:0]);
                        3'b001: $fwrite(fd, "%08h mem %08h %04h\n",
                                TB.DUT.memwb.q.Address,
                                TB.DUT.memwb.q.ALUResult,
                                TB.DUT.memwb.q.WD[15:0]);
                        3'b010: $fwrite(fd, "%08h mem %08h %08h\n",
                                TB.DUT.memwb.q.Address,
                                TB.DUT.memwb.q.ALUResult,
                                TB.DUT.memwb.q.WD);
                    endcase
                end

                7'b0000011:
                    $fwrite(fd, "%08h %02d %08h mem %08h\n",
                        TB.DUT.memwb.q.Address,
                        TB.DUT.memwb.q.rd,
                        TB.DUT.rm.WD3,
                        TB.DUT.memwb.q.ALUResult);

                7'b0110011, 7'b0010011, 7'b1100011, 7'b1101111, 7'b1100111, 7'b0110011, 7'b0010111:
                    if ((TB.DUT.memwb.q.instr == 32'h0000013)||(TB.DUT.memwb.q.instr[6:0] == 7'b1100011)||(TB.DUT.memwb.q.rd == '0))
                        $fwrite(fd, "%08h\n", TB.DUT.memwb.q.Address);
                    else
                        $fwrite(fd, "%08h %02d %08h\n",
                        TB.DUT.memwb.q.Address,
                        TB.DUT.memwb.q.rd,
                        (TB.DUT.memwb.q.RegW ? TB.DUT.rm.WD3 : 32'b0));

                default: begin end
            endcase
            $fflush(fd);
        end
    end
endmodule