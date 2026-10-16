module Systolic_Array(
    input logic CLK,
    input logic RST,
    input logic VALID_IN_ARRAY,
    input logic CLR_ACCUMULATE,
    input logic signed [15:0] W_A [0:3],
    input logic signed [15:0] W_B [0:3],
    output logic signed [33:0] ACCUMULATE_OUT [0:3][0:3],
    output logic VALID_OUT_CONTROLLER
);


logic signed [15:0] PE_to_PE_A [0:3][0:4];
logic signed [15:0] PE_to_PE_B [0:4][0:3];

logic PE_to_PE_Valid_A [0:3][0:4];
logic PE_to_PE_Valid_B [0:4][0:3];

logic PE_to_PE_CLR_A [0:3][0:4];
logic PE_to_PE_CLR_B [0:4][0:3];

                


genvar ROW, COL;

generate 
    
    for (ROW = 0; ROW < 4; ROW ++) begin : ROW_GEN
        for (COL = 0; COL < 4; COL ++) begin : COL_GEN
            
            Processing_Element PE (
                .CLK(CLK),
                .RST(RST),
                
                .SRCA(PE_to_PE_A[ROW][COL]),
                .SRCB(PE_to_PE_B[ROW][COL]),
                
                .SRCA_OUT(PE_to_PE_A[ROW][COL+1]),
                .SRCB_OUT(PE_to_PE_B[ROW+1][COL]),
                
                .ACCUMULATE(ACCUMULATE_OUT[ROW][COL]),
                
                .VALID_INA(PE_to_PE_Valid_A[ROW][COL]),
                .VALID_INB(PE_to_PE_Valid_B[ROW][COL]),
                
                .VALID_OUTA(PE_to_PE_Valid_A[ROW][COL+1]),
                .VALID_OUTB(PE_to_PE_Valid_B[ROW+1][COL]),
                
                .CLR_IN_A(CLR_ACCUMULATE),
                .CLR_IN_B(CLR_ACCUMULATE),
                
                .CLR_OUT_A(PE_to_PE_CLR_A[ROW][COL+1]),
                .CLR_OUT_B(PE_to_PE_CLR_B[ROW+1][COL])
                
                );
                end
                end
                
                endgenerate

generate
    
    for (ROW = 0; ROW < 4; ROW ++) begin
        assign PE_to_PE_A[ROW][0] = W_A[ROW];
        end
    
    for (COL = 0; COL < 4; COL ++) begin
        assign PE_to_PE_B[0][COL] = W_B[COL];
        end
        
        endgenerate

generate

    for (ROW=0; ROW<4; ROW++) begin
        assign PE_to_PE_Valid_A[ROW][0] = VALID_IN_ARRAY;
        end

    for (COL=0; COL<4; COL++) begin
        assign PE_to_PE_Valid_B[0][COL] = VALID_IN_ARRAY;
        end
        
        endgenerate
        
generate
    
    for (ROW = 0; ROW<4; ROW++) begin
        assign PE_to_PE_CLR_A[ROW][0] = CLR_ACCUMULATE;
        end
    
    for (COL = 0; COL<4; COL++) begin
        assign PE_to_PE_CLR_B[0][COL] = CLR_ACCUMULATE;
        end
        
        endgenerate


logic VALID_D1, VALID_D2, VALID_D3, VALID_D4, VALID_D5, VALID_D6;
logic VALID_OUT_TESTPIN;

             
assign VALID_OUT_TESTPIN = PE_to_PE_Valid_A[3][4]&&PE_to_PE_Valid_B[4][3];

always_ff @(posedge CLK) begin
    if (RST) begin
        VALID_D1 <= 1'b0;
        VALID_D2 <= 1'b0;
        VALID_D3 <= 1'b0;
        VALID_D4 <= 1'b0;
        VALID_D5 <= 1'b0;
        VALID_D6 <= 1'b0;
    end else begin
        VALID_D1 <= PE_to_PE_Valid_A[3][4]&&PE_to_PE_Valid_B[4][3];
        VALID_D2 <= VALID_D1;
        VALID_D3 <= VALID_D2;
        VALID_D4 <= VALID_D3;
        VALID_D5 <= VALID_D4;
        VALID_D6 <= VALID_D5;
    end
end

assign VALID_OUT_CONTROLLER = VALID_D6 && VALID_OUT_TESTPIN;

endmodule