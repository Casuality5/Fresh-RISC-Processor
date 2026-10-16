module DataPath(

          input logic CLK,
          input logic RST,
          input logic PACKING_ENABLE,                                           // FORM DMAC
          input logic SKEW,                                                     // FROM DMAC
          input logic CLR_IN,                                                   // FROM DMAC
          input logic CLR_ACCUMULATE,                                           // FROM DMAC
          input logic START,                                                    // FROM DMAC
          input logic [8:0] ADDR,                                               // FROM DMAC
          input logic RE,                                                       // FROM DMAC
          
          input logic [15:0] UNPACKED_INPUT_A,                                  // FROM DMAC
          input logic [15:0] UNPACKED_INPUT_B,                                  // FROM DMAC
          
          output logic READY,                                                   // TO DMAC
          output logic VALID_OUT_CONTROLLER,                                    // TO DMAC
          output logic DONE,                                                    // TO DMAC
          output logic [33:0] BUF_DATA_OUT                                          // TO DMAC
    );
    
    
    logic [255:0] IPU_to_TIS_WIRE [0:1];
    logic [447:0] TIS_to_TB_WIRE [0:1];
    logic [447:0] TB_to_TR_WIRE [0:1];
    logic signed [15:0] TR_to_SA_WIRE_A[0:3];
    logic signed [15:0] TR_to_SA_WIRE_B[0:3];
    logic signed [33:0] SA_to_OB_WIRE [0:3][0:3];
    
    logic SKEW_DONE_to_VALID_IN_BUFFER;
    logic VALID_OUT_BUFFER_to_VALID_REGISTER_IN_WIRE;
    logic VALID_REGISTER_OUT_to_VALID_IN_ARRAY_WIRE;
    
    
    Input_Packing_Unit IPU(
          
          .CLK(CLK),
          .RST(RST),
          .PACKING_ENABLE(PACKING_ENABLE),
          .UNPACKED_INPUT_A(UNPACKED_INPUT_A),
          .UNPACKED_INPUT_B(UNPACKED_INPUT_B),
          
          .PACKED_OUTPUT_A(IPU_to_TIS_WIRE[0]),
          .PACKED_OUTPUT_B(IPU_to_TIS_WIRE[1]),
          .READY(READY)
          );
          
    Tensor_Input_Skewer TIS(
          
          .CLK(CLK),
          .RST(RST),
          .SKEW(SKEW),
          .PACKED_INPUT_A(IPU_to_TIS_WIRE[0]),
          .PACKED_INPUT_B(IPU_to_TIS_WIRE[1]),
          
          .SKEW_DONE(SKEW_DONE_to_VALID_IN_BUFFER),
          .SKEWED_OUTPUT_A(TIS_to_TB_WIRE[0]),
          .SKEWED_OUTPUT_B(TIS_to_TB_WIRE[1])
          );
          
    Tensor_Buffer TB (
          
          .CLK(CLK),
          .RST(RST),
          .MATRIX_A(TIS_to_TB_WIRE[0]),
          .MATRIX_B(TIS_to_TB_WIRE[1]),
          .VALID_BUFFER_IN(SKEW_DONE_to_VALID_IN_BUFFER),
          
          .VALID_BUFFER_OUT(VALID_OUT_BUFFER_to_VALID_REGISTER_IN_WIRE),
          .MATRIX_A_READ(TB_to_TR_WIRE[0]),
          .MATRIX_B_READ(TB_to_TR_WIRE[1])
          );
          
    Tensor_Registers TR (
          
          .CLK(CLK),
          .RST(RST),
          .CLR_IN(CLR_IN),
          .SRCA(TB_to_TR_WIRE[0]),
          .SRCB(TB_to_TR_WIRE[1]),
          .VALID_REGISTER_IN(VALID_OUT_BUFFER_to_VALID_REGISTER_IN_WIRE),
          
          .VALID_REGISTER_OUT(VALID_REGISTER_OUT_to_VALID_IN_ARRAY_WIRE),
          .ROW_OUT(TR_to_SA_WIRE_A[0:3]),
          .COL_OUT(TR_to_SA_WIRE_B[0:3])
          );
          
    Systolic_Array SA (
          
          .CLK(CLK),
          .RST(RST),
          .VALID_IN_ARRAY(VALID_REGISTER_OUT_to_VALID_IN_ARRAY_WIRE),
          .CLR_ACCUMULATE(CLR_ACCUMULATE),
          .W_A(TR_to_SA_WIRE_A[0:3]),
          .W_B(TR_to_SA_WIRE_B[0:3]),
          
          .ACCUMULATE_OUT(SA_to_OB_WIRE),
          .VALID_OUT_CONTROLLER(VALID_OUT_CONTROLLER)
          );
                
    Output_Buffer OB (
          
          .CLK(CLK),
          .RST(RST),
          .START(START),
          .ADDR(ADDR),
          .RE(RE),
          .ACCUMULATE_IN(SA_to_OB_WIRE),
          
          .DONE(DONE),
          .BUF_DATA_OUT(BUF_DATA_OUT)
          );                     
  
endmodule
