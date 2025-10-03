// pooling.v
module pooling (
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

    output reg signed [15:0] max_out,
    output reg valid_out
  );

  // --- Pipeline Stage 1 Registers ---
  reg signed [15:0] max_s1_0, max_s1_1, max_s1_2, max_s1_3;
  reg signed [15:0] last_data_s1; // 用於儲存 data_in8
  reg valid_d1;

  // --- Pipeline Stage 2 Registers ---
  reg signed [15:0] max_s2_0, max_s2_1;
  reg signed [15:0] last_data_s2; // 延遲一拍的 data_in8
  reg valid_d2;

  // --- Intermediate Wire for Final Comparison ---
  wire signed [15:0] final_max_temp;

  // --- Pipeline Stage 1: 比較樹第一層 ---
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      valid_d1 <= 1'b0;
      max_s1_0 <= 16'h8000;
      max_s1_1 <= 16'h8000;
      max_s1_2 <= 16'h8000;
      max_s1_3 <= 16'h8000;
      last_data_s1 <= 16'h8000;
    end
    else
    begin
      if (valid_in)
      begin
        max_s1_0     <= (data_in0 > data_in1) ? data_in0 : data_in1;
        max_s1_1     <= (data_in2 > data_in3) ? data_in2 : data_in3;
        max_s1_2     <= (data_in4 > data_in5) ? data_in4 : data_in5;
        max_s1_3     <= (data_in6 > data_in7) ? data_in6 : data_in7;
        last_data_s1 <= data_in8;
      end
      valid_d1 <= valid_in;
    end
  end

  // --- Pipeline Stage 2: 比較樹第二層 ---
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      valid_d2 <= 1'b0;
      max_s2_0 <= 16'h8000;
      max_s2_1 <= 16'h8000;
      last_data_s2 <= 16'h8000;
    end
    else
    begin
      if (valid_d1)
      begin
        max_s2_0     <= (max_s1_0 > max_s1_1) ? max_s1_0 : max_s1_1;
        max_s2_1     <= (max_s1_2 > max_s1_3) ? max_s1_2 : max_s1_3;
        last_data_s2 <= last_data_s1;
      end
      valid_d2 <= valid_d1;
    end
  end

  // --- 組合邏輯: 計算最終比較前的最大值 ---
  assign final_max_temp = (max_s2_0 > max_s2_1) ? max_s2_0 : max_s2_1;

  // --- Pipeline Stage 3: 最終比較與輸出 ---
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      max_out   <= 16'd0;
      valid_out <= 1'b0;
    end
    else
    begin
      valid_out <= valid_d2;
      if (valid_d2)
      begin
        // 在這裡完成最後一次比較，並將結果直接存入輸出暫存器
        max_out <= (final_max_temp > last_data_s2) ? final_max_temp : last_data_s2;
      end
    end
  end

endmodule
