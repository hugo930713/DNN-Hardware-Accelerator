module window_buffer_3x3_2d_with_padding (
    input clk,
    input rst_n,
    input valid_in,
    input signed [7:0] data_in,
    input [7:0] img_width,
    input [7:0] img_height,
    input [1:0] padding_mode, // 只支援 01: zero padding
    output reg signed [7:0] data_out0, data_out1, data_out2,
    output reg signed [7:0] data_out3, data_out4, data_out5,
    output reg signed [7:0] data_out6, data_out7, data_out8,
    output reg valid_out
  );
  parameter MAX_WIDTH = 256;
  reg signed [7:0] line0[0:MAX_WIDTH-1];
  reg signed [7:0] line1[0:MAX_WIDTH-1];
  reg signed [7:0] line2[0:MAX_WIDTH-1];
  reg [7:0] col, row;
  integer i;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      col <= 0;
      row <= 0;
      valid_out <= 0;
      for (i = 0; i < MAX_WIDTH; i = i + 1)
      begin
        line0[i] <= 0;
        line1[i] <= 0;
        line2[i] <= 0;
      end
      {data_out0,data_out1,data_out2,data_out3,data_out4,data_out5,data_out6,data_out7,data_out8} <= 0;
    end
    else
    begin
      valid_out <= 0;

      if (valid_in)
      begin
        // 先寫入新像素到line2
        line2[col] <= data_in;

        // 在每行開始時推進line buffer（除了第一行）
        if (row >= 1 && col == 0)
        begin
          for (i = 0; i < MAX_WIDTH; i = i + 1)
          begin
            line0[i] <= line1[i];
            line1[i] <= line2[i];
          end
        end

        // 對於zero padding，第一個window應該在輸入第二行第二個像素時產生
        if (row >= 1 && col >= 1)
        begin
          // 產生3x3 window，完全對應Python標準實現
          // 第一行：上方的zero padding或原始數據
          if (row == 1)
          begin
            data_out0 <= 0;  // 左上 - zero padding
            data_out1 <= 0;  // 上中 - zero padding
            data_out2 <= 0;  // 右上 - zero padding
          end
          else
          begin
            data_out0 <= (col == 1) ? 0 : line0[col-2];  // 左上
            data_out1 <= line0[col-1];    // 上中
            data_out2 <= (col == img_width) ? 0 : line0[col];  // 右上
          end

          // 第二行：中間行
          if (row == 1 && col == 1)
          begin
            data_out3 <= 0;  // 左中 - zero padding
            data_out4 <= line1[0];  // 中心 - 使用line1的第一個值
            data_out5 <= line1[1];  // 右中 - 使用line1的第二個值（關鍵修正）
          end
          else
          begin
            data_out3 <= (col == 1) ? 0 : line1[col-2];  // 左中
            data_out4 <= line1[col-1];    // 中心
            data_out5 <= (col == img_width) ? 0 : line1[col];  // 右中
          end

          // 第三行：下方行
          if (row == 1 && col == 1)
          begin
            data_out6 <= 0;  // 左下 - zero padding
            data_out7 <= line2[0];  // 下中 - 使用line2的第一個值
            data_out8 <= data_in;  // 右下 - 使用當前輸入值
          end
          else
          begin
            data_out6 <= (col == 1) ? 0 : line2[col-2];  // 左下
            data_out7 <= line2[col-1];    // 下中
            data_out8 <= data_in;  // 右下 - 使用當前輸入值
          end

          valid_out <= 1;
        end

        // 更新座標
        if (col == img_width-1)
        begin
          col <= 0;
          row <= row + 1;
        end
        else
        begin
          col <= col + 1;
        end
      end
    end
  end
endmodule
