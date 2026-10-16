module Input_Packing_Unit(
    input  logic CLK,
    input  logic RST,
    input  logic PACKING_ENABLE,

    input  logic signed [15:0] UNPACKED_INPUT_A,
    input  logic signed [15:0] UNPACKED_INPUT_B,

    output logic signed [255:0] PACKED_OUTPUT_A,
    output logic signed [255:0] PACKED_OUTPUT_B,

    output logic READY
);

    logic READY_A;
    logic READY_B;

    Input_Packing_Unit_A IPUA(
        .CLK(CLK),
        .RST(RST),
        .ENABLE(PACKING_ENABLE),

        .UNPACKED_INPUT_A(UNPACKED_INPUT_A),
        .PACKED_OUTPUT_A(PACKED_OUTPUT_A),

        .READY_A(READY_A)
    );

    Input_Packing_Unit_B IPUB(
        .CLK(CLK),
        .RST(RST),
        .ENABLE(PACKING_ENABLE),

        .UNPACKED_INPUT_B(UNPACKED_INPUT_B),
        .PACKED_OUTPUT_B(PACKED_OUTPUT_B),

        .READY_B(READY_B)
    );

    assign READY = READY_A & READY_B;

endmodule
