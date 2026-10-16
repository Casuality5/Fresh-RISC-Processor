module SoCTB;

    logic clk;
    logic rst;
    logic CTRL;
    
    
    SoC DUT (clk,rst);
    
    always #5 clk = ~clk;
    
    initial begin
    
        clk = 0;
        rst = 1;
        #13 rst = 0;
        
        #100000;
        $finish;
    end
        


endmodule