module Input_Packing_Unit_B(
    input logic CLK,
    input logic RST,
    input logic ENABLE,
    input logic signed [15:0] UNPACKED_INPUT_B,
    output logic signed [255:0] PACKED_OUTPUT_B,
    output logic READY_B
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

    
logic [3:0] COUNT_B;

   always_ff @(posedge CLK) begin
    if (RST) begin
        COUNT_B         <= 0;
        PACKED_OUTPUT_B <= '0;
        READY_B        <= 0;
    end
    else if (ENABLE) begin

        PACKED_OUTPUT_B[COUNT_B*16 +: 16] <= UNPACKED_INPUT_B;

        if (COUNT_B == 4'd15) begin
            READY_B <= 1'b1;
            COUNT_B <= 0;
        end
        else begin
            READY_B <= 1'b0;
            COUNT_B <= COUNT_B + 1'b1;
        end
    end
    else begin
        READY_B <= 1'b0;
    end
end
endmodule
