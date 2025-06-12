module pipeline_controller (
  input clk,
  input rst_n,

  // window buffer inputs
  input win_valid_out,
  input signed [7:0] data_in0,
  input signed [7:0] data_in1,
  input signed [7:0] data_in2,
  input signed [7:0] data_in3,
  input signed [7:0] data_in4,
  input signed [7:0] data_in5,
  input signed [7:0] data_in6,
  input signed [7:0] data_in7,
  input signed [7:0] data_in8,

  // conv3x3 multicycle interface
  output reg conv_valid_in,
  output reg signed [7:0] conv_data_in0,
  output reg signed [7:0] conv_data_in1,
  output reg signed [7:0] conv_data_in2,
  output reg signed [7:0] conv_data_in3,
  output reg signed [7:0] conv_data_in4,
  output reg signed [7:0] conv_data_in5,
  output reg signed [7:0] conv_data_in6,
  output reg signed [7:0] conv_data_in7,
  output reg signed [7:0] conv_data_in8,
  input conv_valid_out,
  input signed [15:0] conv_data_out,

  // relu multicycle interface
  output reg relu_valid_in,
  output reg signed [7:0] relu_data_in,
  input relu_valid_out,
  input [7:0] relu_data_out,

  // pooling multicycle interface
  output reg pool_valid_in,
  output reg signed [7:0] pool_data_in0,
  output reg signed [7:0] pool_data_in1,
  output reg signed [7:0] pool_data_in2,
  output reg signed [7:0] pool_data_in3,
  output reg signed [7:0] pool_data_in4,
  output reg signed [7:0] pool_data_in5,
  output reg signed [7:0] pool_data_in6,
  output reg signed [7:0] pool_data_in7,
  output reg signed [7:0] pool_data_in8,
  input pool_valid_out,
  input signed [7:0] pool_data_out,

  // final output
  output reg valid_final_out,
  output reg [7:0] data_final_out
);

  // 狀態定義
  localparam IDLE           = 3'd0;
  localparam WAIT_WIN_VALID = 3'd1;
  localparam CONV_START     = 3'd2;
  localparam WAIT_CONV_DONE = 3'd3;
  localparam RELU_START     = 3'd4;
  localparam WAIT_RELU_DONE = 3'd5;
  localparam POOL_START     = 3'd6;
  localparam WAIT_POOL_DONE = 3'd7;

  reg [2:0] state, next_state;

  // conv_latch 改用獨立變數
  reg signed [7:0] conv_latch0, conv_latch1, conv_latch2;
  reg signed [7:0] conv_latch3, conv_latch4, conv_latch5;
  reg signed [7:0] conv_latch6, conv_latch7, conv_latch8;

  integer i; // 可選，這裡沒用到迴圈

  // state machine sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;

      conv_valid_in <= 0;
      relu_valid_in <= 0;
      pool_valid_in <= 0;
      valid_final_out <= 0;

      conv_data_in0 <= 0; conv_data_in1 <= 0; conv_data_in2 <= 0;
      conv_data_in3 <= 0; conv_data_in4 <= 0; conv_data_in5 <= 0;
      conv_data_in6 <= 0; conv_data_in7 <= 0; conv_data_in8 <= 0;

      relu_data_in <= 0;

      pool_data_in0 <= 0; pool_data_in1 <= 0; pool_data_in2 <= 0;
      pool_data_in3 <= 0; pool_data_in4 <= 0; pool_data_in5 <= 0;
      pool_data_in6 <= 0; pool_data_in7 <= 0; pool_data_in8 <= 0;

      conv_latch0 <= 0; conv_latch1 <= 0; conv_latch2 <= 0;
      conv_latch3 <= 0; conv_latch4 <= 0; conv_latch5 <= 0;
      conv_latch6 <= 0; conv_latch7 <= 0; conv_latch8 <= 0;

    end else begin
      state <= next_state;

      case(state)
        IDLE: begin
          valid_final_out <= 0;
          conv_valid_in <= 0;
          relu_valid_in <= 0;
          pool_valid_in <= 0;
        end

        WAIT_WIN_VALID: begin
          valid_final_out <= 0;
          conv_valid_in <= 0;
          relu_valid_in <= 0;
          pool_valid_in <= 0;

          if (win_valid_out) begin
            conv_latch0 <= data_in0; conv_latch1 <= data_in1; conv_latch2 <= data_in2;
            conv_latch3 <= data_in3; conv_latch4 <= data_in4; conv_latch5 <= data_in5;
            conv_latch6 <= data_in6; conv_latch7 <= data_in7; conv_latch8 <= data_in8;
          end
        end

        CONV_START: begin
          conv_valid_in <= 1;

          conv_data_in0 <= conv_latch0;
          conv_data_in1 <= conv_latch1;
          conv_data_in2 <= conv_latch2;
          conv_data_in3 <= conv_latch3;
          conv_data_in4 <= conv_latch4;
          conv_data_in5 <= conv_latch5;
          conv_data_in6 <= conv_latch6;
          conv_data_in7 <= conv_latch7;
          conv_data_in8 <= conv_latch8;
        end

        WAIT_CONV_DONE: begin
          conv_valid_in <= 0;
        end

        RELU_START: begin
          relu_valid_in <= 1;
          relu_data_in <= conv_data_out[7:0];
        end

        WAIT_RELU_DONE: begin
          relu_valid_in <= 0;
        end

        POOL_START: begin
          pool_valid_in <= 1;

          pool_data_in0 <= relu_data_out; pool_data_in1 <= relu_data_out; pool_data_in2 <= relu_data_out;
          pool_data_in3 <= relu_data_out; pool_data_in4 <= relu_data_out; pool_data_in5 <= relu_data_out;
          pool_data_in6 <= relu_data_out; pool_data_in7 <= relu_data_out; pool_data_in8 <= relu_data_out;
        end

        WAIT_POOL_DONE: begin
          pool_valid_in <= 0;
        end

      endcase

      if (pool_valid_out) begin
        valid_final_out <= 1;
        data_final_out <= pool_data_out;
      end else begin
        valid_final_out <= 0;
      end
    end
  end

  // next state combinational logic
  always @(*) begin
    next_state = state;

    case(state)
      IDLE: next_state = WAIT_WIN_VALID;

      WAIT_WIN_VALID:
        if (win_valid_out) next_state = CONV_START;

      CONV_START: next_state = WAIT_CONV_DONE;

      WAIT_CONV_DONE:
        if (conv_valid_out) next_state = RELU_START;

      RELU_START: next_state = WAIT_RELU_DONE;

      WAIT_RELU_DONE:
        if (relu_valid_out) next_state = POOL_START;

      POOL_START: next_state = WAIT_POOL_DONE;

      WAIT_POOL_DONE:
        if (pool_valid_out) next_state = WAIT_WIN_VALID;

      default: next_state = IDLE;
    endcase
  end

endmodule


