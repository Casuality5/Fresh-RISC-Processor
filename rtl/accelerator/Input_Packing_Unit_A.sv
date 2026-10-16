module Input_Packing_Unit_A(
    input logic CLK,
    input logic RST,
    input logic ENABLE,
    input logic signed [15:0] UNPACKED_INPUT_A,
    output logic signed [255:0] PACKED_OUTPUT_A,
    output logic READY_A
    );

localparam CHUNK1   = 4'h0;
localparam CHUNK2   = 4'h1;
localparam CHUNK3   = 4'h2;
localparam CHUNK4   = 4'h3;
localparam CHUNK5   = 4'h4;
localparam CHUNK6   = 4'h5;
localparam CHUNK7   = 4'h6;
localparam CHUNK8   = 4'h7;
localparam CHUNK9   = 4'h8;
localparam CHUNK10  = 4'h9;
localparam CHUNK11  = 4'hA;
localparam CHUNK12  = 4'hB;
localparam CHUNK13  = 4'hC;
localparam CHUNK14  = 4'hD;
localparam CHUNK15  = 4'hE;
localparam CHUNK16  = 4'hF;

    
logic [3:0] COUNT_A;   

   always_ff @(posedge CLK) begin
    if (RST) begin
        COUNT_A         <= 0;
        PACKED_OUTPUT_A <= 0;
        READY_A         <= 0;
    end
    else if (ENABLE) begin

        PACKED_OUTPUT_A[COUNT_A*16 +: 16] <= UNPACKED_INPUT_A;

        if (COUNT_A == 4'd15) begin
            READY_A <= 1'b1;
            COUNT_A <= 0;
        end
        else begin
            READY_A <= 1'b0;
            COUNT_A <= COUNT_A + 1'b1;
        end
    end
    else begin
        READY_A <= 1'b0;
    end
end


endmodule
