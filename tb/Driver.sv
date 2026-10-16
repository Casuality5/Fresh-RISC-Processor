`timescale 1ns / 1ps

module Driver;
    
    logic clk;
    logic rst;
    integer file;
    
    Top DUT(clk, rst);
    
    always #5 clk = ~clk;
    
    task run(input int cycles);
        
        repeat(cycles) begin
            @(posedge clk);
            $display("ADDRESS: %h |INSTRUCTION: %h | RegW: %b | RegDataW: %h | RS1: %d | RS2: %d | RD: %d | Branch: %b", 
            Driver.DUT.rm.MB.Address,
            Driver.DUT.rm.MB.instr,
            Driver.DUT.rm.MB.RegW,
            Driver.DUT.rm.WD3,
            Driver.DUT.rm.MB.RS1,
            Driver.DUT.rm.MB.RS2,
            Driver.DUT.rm.MB.rd, 
            Driver.DUT.rm.MB.Branch_taken);
        end
    endtask
    
    initial begin
        
        Packet P;
        
        P = new();

        
        clk = 0;
        rst = 1;
        #5 rst = 0;
        file = $fopen("D:/Fresh/Fresh.srcs/sim_1/new/Program.mem", "w");

        if (file == 0)
            $fatal("FAILED TO OPEN Program.mem");

        $display("Program.mem CLEARED");

        $fclose(file);
        repeat(100) begin
           
            
            assert(P.randomize());
            
            P.encode();
            
            P.payload();
        end
        $fclose(file);
        
        run(120);
        
        $finish;
    end   
endmodule
