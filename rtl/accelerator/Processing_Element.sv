module Processing_Element (
    input logic CLK,
    input logic RST,
    input logic VALID_INA, VALID_INB,
    input logic CLR_IN_A, CLR_IN_B,
    input logic signed [15:0] SRCA, SRCB,
    output logic signed [15:0] SRCA_OUT, SRCB_OUT,
    output logic signed [33:0] ACCUMULATE,
    output logic VALID_OUTA, VALID_OUTB,
    output logic CLR_OUT_A, CLR_OUT_B
);




always_ff @(posedge CLK) begin
    if (RST) begin
        ACCUMULATE  <= 0;
        SRCA_OUT    <= 0;
        SRCB_OUT    <= 0;
        VALID_OUTA  <= 0;
        VALID_OUTB  <= 0;
        CLR_OUT_A   <= 0;
        CLR_OUT_B   <= 0;
    end
    else begin
        SRCA_OUT    <= SRCA;
        SRCB_OUT    <= SRCB;
        VALID_OUTA  <= VALID_INA;
        VALID_OUTB  <= VALID_INB;
        CLR_OUT_A   <= CLR_IN_A;
        CLR_OUT_B   <= CLR_IN_B;

        if (CLR_IN_A) begin
                    ACCUMULATE <= 0;
                    end
                    else if (VALID_INA && VALID_INB) begin
                    ACCUMULATE <= ACCUMULATE + SRCA * SRCB;
                    end
    end
end

endmodule
