// relu.v
module relu #(parameter WIDTH_IN = 16, WIDTH_OUT = 8) (
    input clk,
    input rst_n,
    input valid_in,
    input  signed [WIDTH_IN-1:0] data_in,
    output reg [WIDTH_OUT-1:0] data_out,
    output reg valid_out
  );

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out <= 0;
      valid_out <= 0;
    end
    else if (valid_in)
    begin
      // ReLU 函數處理
      if (data_in > 0)
      begin
        if (data_in > 127)   // Saturate to int8 最大值
          data_out <= 8'd127;
        else
          data_out <= data_in[7:0];  // data_in 保證在 0~127 之間，取低 8 位沒問題
      end
      else
      begin
        data_out <= 8'd0;
      end

      valid_out <= 1;  // 當 valid_in 有效時，valid_out 設為 1
    end
    else
    begin
      valid_out <= 0;  // 當 valid_in 不有效時，valid_out 設為 0
    end
  end

endmodule
