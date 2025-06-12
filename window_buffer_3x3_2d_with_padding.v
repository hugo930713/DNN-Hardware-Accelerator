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

        // 修正：產生完整的 8×8 輸出，對應 Python 標準實現
        // 第一個 window 在 row=0, col=0 時產生
        if (row >= 0 && col >= 0)
        begin
          // 第一行：上方的zero padding或原始數據
          if (row == 0)
          begin
            data_out0 <= 0;  // 左上 - zero padding
            data_out1 <= 0;  // 上中 - zero padding
            data_out2 <= 0;  // 右上 - zero padding
          end
          else if (row == 1)
          begin
            data_out0 <= 0;  // 左上 - zero padding
            data_out1 <= 0;  // 上中 - zero padding
            data_out2 <= 0;  // 右上 - zero padding
          end
          else
          begin
            data_out0 <= (col == 0) ? 0 : line0[col-1];  // 左上
            data_out1 <= line0[col];    // 上中
            data_out2 <= (col == img_width-1) ? 0 : line0[col+1];  // 右上
          end

          // 第二行：中間行
          if (row == 0)
          begin
            data_out3 <= 0;  // 左中 - zero padding
            data_out4 <= 0;  // 中心 - zero padding
            data_out5 <= 0;  // 右中 - zero padding
          end
          else if (row == 1)
          begin
            data_out3 <= (col == 0) ? 0 : line1[col-1];  // 左中
            data_out4 <= line1[col];    // 中心
            data_out5 <= (col == img_width-1) ? 0 : line1[col+1];  // 右中
          end
          else
          begin
            data_out3 <= (col == 0) ? 0 : line1[col-1];  // 左中
            data_out4 <= line1[col];    // 中心
            data_out5 <= (col == img_width-1) ? 0 : line1[col+1];  // 右中
          end

          // 第三行：下方行
          if (row == 0)
          begin
            data_out6 <= 0;  // 左下 - zero padding
            data_out7 <= 0;  // 下中 - zero padding
            data_out8 <= 0;  // 右下 - zero padding
          end
          else if (row == 1)
          begin
            data_out6 <= (col == 0) ? 0 : line2[col-1];  // 左下
            data_out7 <= line2[col];    // 下中
            data_out8 <= (col == img_width-1) ? 0 : line2[col+1];  // 右下
          end
          else
          begin
            data_out6 <= (col == 0) ? 0 : line2[col-1];  // 左下
            data_out7 <= line2[col];    // 下中
            data_out8 <= (col == img_width-1) ? 0 : line2[col+1];  // 右下
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
