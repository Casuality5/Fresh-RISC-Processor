module Tensor_Input_Skewer(
    input  logic CLK,
    input  logic RST,
    input  logic SKEW,
    input  logic signed [255:0] PACKED_INPUT_A,
    input  logic signed [255:0] PACKED_INPUT_B,
    output logic SKEW_DONE,
    output logic signed [447:0] SKEWED_OUTPUT_A,
    output logic signed [447:0] SKEWED_OUTPUT_B
);

always_ff @(posedge CLK) begin
    if (RST || !SKEW) begin
        SKEWED_OUTPUT_A <= '0;
        SKEWED_OUTPUT_B <= '0;
        SKEW_DONE       <= 1'b0;
    end
    else begin

        // A enters from LEFT
        SKEWED_OUTPUT_A <= {

            // Cycle 6
            16'h0000, 16'h0000, 16'h0000, PACKED_INPUT_A[15:0],

            // Cycle 5
            16'h0000, 16'h0000,
            PACKED_INPUT_A[79:64],
            PACKED_INPUT_A[31:16],

            // Cycle 4
            16'h0000,
            PACKED_INPUT_A[143:128],
            PACKED_INPUT_A[95:80],
            PACKED_INPUT_A[47:32],

            // Cycle 3
            PACKED_INPUT_A[207:192],
            PACKED_INPUT_A[159:144],
            PACKED_INPUT_A[111:96],
            PACKED_INPUT_A[63:48],

            // Cycle 2
            PACKED_INPUT_A[223:208],
            PACKED_INPUT_A[175:160],
            PACKED_INPUT_A[127:112],
            16'h0000,

            // Cycle 1
            PACKED_INPUT_A[239:224],
            PACKED_INPUT_A[191:176],
            16'h0000,
            16'h0000,

            // Cycle 0
            PACKED_INPUT_A[255:240],
            16'h0000,
            16'h0000,
            16'h0000
        };

        // B enters from TOP
                SKEWED_OUTPUT_B <= {
            // Cycle 6 (Column 3)
            16'h0000, 16'h0000, 16'h0000, PACKED_INPUT_B[15:0],     // B[3][3]

            // Cycle 5 (Column 2 & 3)
            16'h0000, 16'h0000,
            PACKED_INPUT_B[31:16],                                  // B[3][2]
            PACKED_INPUT_B[79:64],                                  // B[2][3]

            // Cycle 4 (Column 1, 2, 3)
            16'h0000,
            PACKED_INPUT_B[47:32],                                  // B[3][1]
            PACKED_INPUT_B[95:80],                                  // B[2][2]
            PACKED_INPUT_B[143:128],                                // B[1][3]

            // Cycle 3 (Column 0, 1, 2, 3)
            PACKED_INPUT_B[63:48],                                  // B[3][0]
            PACKED_INPUT_B[111:96],                                 // B[2][1]
            PACKED_INPUT_B[159:144],                                // B[1][2]
            PACKED_INPUT_B[207:192],                                // B[0][3]

            // Cycle 2 (Column 0, 1, 2)
            PACKED_INPUT_B[127:112],                                // B[2][0]
            PACKED_INPUT_B[175:160],                                // B[1][1]
            PACKED_INPUT_B[223:208],                                // B[0][2]
            16'h0000,

            // Cycle 1 (Column 0, 1)
            PACKED_INPUT_B[191:176],                                // B[1][0]
            PACKED_INPUT_B[239:224],                                // B[0][1]
            16'h0000,
            16'h0000,

            // Cycle 0 (Column 0)
            PACKED_INPUT_B[255:240],                                // B[0][0]
            16'h0000,
            16'h0000,
            16'h0000
        };


        SKEW_DONE <= 1'b1;
    end
end

endmodule