// conv_3x3.v

module conv_3x3(
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

    input signed [7:0] weight0,
    input signed [7:0] weight1,
    input signed [7:0] weight2,
    input signed [7:0] weight3,
    input signed [7:0] weight4,
    input signed [7:0] weight5,
    input signed [7:0] weight6,
    input signed [7:0] weight7,
    input signed [7:0] weight8,

    output reg signed [15:0] data_out,  // 16位輸出，不應用飽和運算
    output reg valid_out
  );

  reg signed [19:0] mult_sum; // 累加器寬度夠大
  reg valid_in_d;

  // 先做乘加，累加到夠寬的暫存器
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      mult_sum <= 0;
      valid_in_d <= 0;
    end
    else
    begin
      // 使用原始卷積核：[1, 0, -1]
      mult_sum <=
               $signed(data_in0) * $signed(weight0) +
               $signed(data_in1) * $signed(weight1) +
               $signed(data_in2) * $signed(weight2) +
               $signed(data_in3) * $signed(weight3) +
               $signed(data_in4) * $signed(weight4) +
               $signed(data_in5) * $signed(weight5) +
               $signed(data_in6) * $signed(weight6) +
               $signed(data_in7) * $signed(weight7) +
               $signed(data_in8) * $signed(weight8);
      valid_in_d <= valid_in;
    end
  end

  // 直接輸出mult_sum的低16位，不應用飽和運算
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out <= 0;
      valid_out <= 0;
    end
    else
    begin
      // 直接輸出mult_sum的低16位
      data_out <= mult_sum[15:0];
      valid_out <= valid_in_d;
    end
  end

endmodule
