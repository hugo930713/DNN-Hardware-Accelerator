module pool_multicycle (
  input clk,
  input rst_n,
  input valid_in,
  input signed [7:0] data_in0,
  input signed [7:0] data_in1,
  input signed [7:0] data_in2,
  input signed [7:0] data_in3,
  input signed [7:0] data_in4,
  input signed [7:0] data_in5,
  input signed [7:0] data_in6,
  input signed [7:0] data_in7,
  input signed [7:0] data_in8,
  output reg valid_out,
  output reg signed [7:0] data_out
);

  // Max pooling 3x3: 選最大值，假設多週期3個週期做比較

  reg [1:0] cycle_cnt;
  reg signed [7:0] max_val;

  reg processing;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_out <= 0;
      cycle_cnt <= 0;
      max_val <= -128; // 最小值初始化
      processing <= 0;
      data_out <= 0;
    end else begin
      if (valid_in && !processing) begin
        processing <= 1;
        cycle_cnt <= 0;
        max_val <= -128;
        valid_out <= 0;
      end else if (processing) begin
        case (cycle_cnt)
          2'd0: begin
            max_val <= (data_in0 > data_in1) ? data_in0 : data_in1;
            max_val <= (max_val > data_in2) ? max_val : data_in2;
          end
          2'd1: begin
            max_val <= (max_val > data_in3) ? max_val : data_in3;
            max_val <= (max_val > data_in4) ? max_val : data_in4;
            max_val <= (max_val > data_in5) ? max_val : data_in5;
          end
          2'd2: begin
            max_val <= (max_val > data_in6) ? max_val : data_in6;
            max_val <= (max_val > data_in7) ? max_val : data_in7;
            max_val <= (max_val > data_in8) ? max_val : data_in8;
          end
        endcase

        if (cycle_cnt == 2'd2) begin
          data_out <= max_val;
          valid_out <= 1;
          processing <= 0;
        end else begin
          cycle_cnt <= cycle_cnt + 1;
          valid_out <= 0;
        end
      end else begin
        valid_out <= 0;
      end
    end
  end

endmodule

