module Tensor_Buffer(
    input logic     CLK,
    input logic     RST,
    input logic     [447:0] MATRIX_A, // store it in row-wise order ( will be transformation matrix )
    input logic     [447:0] MATRIX_B, // store it in col-wise order ( will be coordinates matrix )
    input logic VALID_BUFFER_IN,
    output logic VALID_BUFFER_OUT,
    output logic    [447:0] MATRIX_A_READ,
    output logic    [447:0] MATRIX_B_READ
    );
    
    

  
    
    always_ff @(posedge CLK) begin
        if (RST) begin
            MATRIX_A_READ <= 0;
            MATRIX_B_READ <= 0;
            VALID_BUFFER_OUT <= 0;
            end
            
            else begin
                VALID_BUFFER_OUT <= VALID_BUFFER_IN;
                MATRIX_A_READ <= MATRIX_A;
                MATRIX_B_READ <= MATRIX_B;
            end
    end
endmodule
