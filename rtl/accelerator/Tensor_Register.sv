module Tensor_Registers(

    input logic CLK,
    input logic RST,
    input logic CLR_IN,
    input logic [447:0] SRCA,
    input logic [447:0] SRCB,
    input logic VALID_REGISTER_IN,
    output logic VALID_REGISTER_OUT,
    output logic signed [15:0] ROW_OUT [0:3],
    output logic signed [15:0] COL_OUT [0:3]
);
    
    logic [63:0] ROWS [0:6];
    logic [63:0] COLS [0:6];
    logic [2:0] INDEX;
    logic RUNNING;
    
    logic VALID_TR_D1;
    logic START_TRIGGER;
    
    always_ff @(posedge CLK) begin
        if (RST || CLR_IN) begin
            VALID_TR_D1 <= 0;
        end else begin
            VALID_TR_D1 <= VALID_REGISTER_IN;
        end
    end
    
    assign START_TRIGGER = VALID_REGISTER_IN && !VALID_TR_D1;
        
    always_ff @(posedge CLK) begin
        if (RST || CLR_IN) begin
            ROWS[0] <= 0;
            ROWS[1] <= 0;
            ROWS[2] <= 0;
            ROWS[3] <= 0;
            ROWS[4] <= 0;
            ROWS[5] <= 0;
            ROWS[6] <= 0;
            
            COLS[0] <= 0;
            COLS[1] <= 0;
            COLS[2] <= 0;
            COLS[3] <= 0;
            COLS[4] <= 0;
            COLS[5] <= 0;
            COLS[6] <= 0;
        end else if (START_TRIGGER) begin
            ROWS[0] <= SRCA [63:0];
            ROWS[1] <= SRCA [127:64];
            ROWS[2] <= SRCA [191:128];
            ROWS[3] <= SRCA [255:192];
            ROWS[4] <= SRCA [319:256];
            ROWS[5] <= SRCA [383:320];
            ROWS[6] <= SRCA [447:384];
            
            COLS[0] <= SRCB [63:0];
            COLS[1] <= SRCB [127:64];
            COLS[2] <= SRCB [191:128];
            COLS[3] <= SRCB [255:192];
            COLS[4] <= SRCB [319:256];
            COLS[5] <= SRCB [383:320];
            COLS[6] <= SRCB [447:384];
        end
    end
        
    always_ff @(posedge CLK) begin
        if (RST || CLR_IN) begin
            INDEX <= 0;
            VALID_REGISTER_OUT <= 0;
            RUNNING <= 0;
        end else if (START_TRIGGER) begin
            RUNNING <= 1;
            INDEX <= 0;
            VALID_REGISTER_OUT <= 1;
        end else if (RUNNING) begin
            if (INDEX == 3'd6) begin
                RUNNING <= 0;
                INDEX <= 0;
                VALID_REGISTER_OUT <= 0;
            end else begin
                INDEX <= INDEX + 1;
                VALID_REGISTER_OUT <= 1;
            end
        end else begin
            VALID_REGISTER_OUT <= 0;
            INDEX <= 0;
        end
    end
    
    always_comb begin
        ROW_OUT[0] = ROWS[INDEX][63:48];
        ROW_OUT[1] = ROWS[INDEX][47:32];
        ROW_OUT[2] = ROWS[INDEX][31:16];
        ROW_OUT[3] = ROWS[INDEX][15:0];

        COL_OUT[0] = COLS[INDEX][63:48];
        COL_OUT[1] = COLS[INDEX][47:32];
        COL_OUT[2] = COLS[INDEX][31:16];
        COL_OUT[3] = COLS[INDEX][15:0];
    end
    
endmodule