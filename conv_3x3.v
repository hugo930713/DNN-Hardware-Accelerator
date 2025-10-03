// conv_3x3.v
module conv_3x3(
    input clk,
    input rst_n,
    input valid_in,

    input signed [15:0] data_in0,
    input signed [15:0] data_in1,
    input signed [15:0] data_in2,
    input signed [15:0] data_in3,
    input signed [15:0] data_in4,
    input signed [15:0] data_in5,
    input signed [15:0] data_in6,
    input signed [15:0] data_in7,
    input signed [15:0] data_in8,

    input signed [15:0] weight0,
    input signed [15:0] weight1,
    input signed [15:0] weight2,
    input signed [15:0] weight3,
    input signed [15:0] weight4,
    input signed [15:0] weight5,
    input signed [15:0] weight6,
    input signed [15:0] weight7,
    input signed [15:0] weight8,

    output reg signed [15:0] data_out,
    output reg valid_out
  );

  reg signed [31:0] mul_res[0:8];
  reg valid_in_d1;

  reg signed [31:0] add_stage1 [0:3];
  reg signed [31:0] last_mul_res;
  reg valid_in_d2;

  wire signed [32:0] final_sum;

  integer i;

  // --- Pipeline Stage 1: 乘法 ---
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      valid_in_d1 <= 1'b0;
    end
    else
    begin
      if (valid_in)
      begin
        mul_res[0] <= $signed(data_in0) * $signed(weight0);
        mul_res[1] <= $signed(data_in1) * $signed(weight1);
        mul_res[2] <= $signed(data_in2) * $signed(weight2);
        mul_res[3] <= $signed(data_in3) * $signed(weight3);
        mul_res[4] <= $signed(data_in4) * $signed(weight4);
        mul_res[5] <= $signed(data_in5) * $signed(weight5);
        mul_res[6] <= $signed(data_in6) * $signed(weight6);
        mul_res[7] <= $signed(data_in7) * $signed(weight7);
        mul_res[8] <= $signed(data_in8) * $signed(weight8);
      end
      valid_in_d1 <= valid_in;
    end
  end

  // --- Pipeline Stage 2: 加法樹第一層 ---
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      valid_in_d2 <= 1'b0;
      // 重置暫存器
      last_mul_res <= 32'd0;
      for (i = 0; i < 4; i = i + 1)
      begin
        add_stage1[i] <= 32'd0;
      end
    end
    else
    begin
      if (valid_in_d1)
      begin
        add_stage1[0] <= mul_res[0] + mul_res[1];
        add_stage1[1] <= mul_res[2] + mul_res[3];
        add_stage1[2] <= mul_res[4] + mul_res[5];
        add_stage1[3] <= mul_res[6] + mul_res[7];
        last_mul_res  <= mul_res[8];
      end
      valid_in_d2 <= valid_in_d1;
    end
  end

  // --- 組合邏輯: 計算最終總和 ---
  assign final_sum = (add_stage1[0] + add_stage1[1]) + (add_stage1[2] + add_stage1[3]) + last_mul_res;

  // --- Pipeline Stage 3: 輸出暫存器 ---
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out  <= 16'd0;
      valid_out <= 1'b0;
    end
    else
    begin
      valid_out <= valid_in_d2;
      if (valid_in_d2)
      begin
        data_out  <= $signed(final_sum) >>> 8;
      end
    end
  end

endmodule
