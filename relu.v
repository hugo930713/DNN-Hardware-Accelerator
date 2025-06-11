// relu.v
module relu #(parameter WIDTH_IN = 16, WIDTH_OUT = 8) (
    input clk,
    input rst_n,
    input valid_in,
    input  signed [WIDTH_IN-1:0] din,
    output reg [WIDTH_OUT-1:0] dout,
    output reg valid_out
  );

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      dout <= 0;
      valid_out <= 0;
    end
    else if (valid_in)
    begin
      // ReLU 函數處理
      if (din > 0)
      begin
        if (din > 127)   // Saturate to int8 最大值
          dout <= 8'd127;
        else
          dout <= din[7:0];  // din 保證在 0~127 之間，取低 8 位沒問題
      end
      else
      begin
        dout <= 8'd0;
      end

      valid_out <= 1;  // 當 valid_in 有效時，valid_out 設為 1
    end
    else
    begin
      valid_out <= 0;  // 當 valid_in 不有效時，valid_out 設為 0
    end
  end

endmodule
