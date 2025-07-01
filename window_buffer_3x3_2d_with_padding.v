module window_buffer_3x3_2d_with_padding (
    input clk,
    input rst_n,
    input valid_in,
    input signed [7:0] data_in,
    input [7:0] img_width,
    input [7:0] img_height,
    input [1:0] padding_mode, // 00: zero padding
    output reg signed [7:0] data_out0, data_out1, data_out2,
    output reg signed [7:0] data_out3, data_out4, data_out5,
    output reg signed [7:0] data_out6, data_out7, data_out8,
    output reg valid_out
  );

  // 直接儲存整個影像然後逐個輸出窗口
  parameter MAX_SIZE = 256;
  reg signed [7:0] image_mem [0:MAX_SIZE-1];

  reg [7:0] input_count;
  reg [7:0] output_row, output_col;
  reg input_done;

  integer i, j;

  // 根據位置和padding取得像素值
  function signed [7:0] get_pixel;
    input signed [7:0] row, col;
    begin
      if (row < 0 || row >= img_height || col < 0 || col >= img_width)
      begin
        get_pixel = 0; // Zero padding
      end
      else
      begin
        get_pixel = image_mem[row * img_width + col];
      end
    end
  endfunction

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      input_count <= 0;
      output_row <= 0;
      output_col <= 0;
      input_done <= 0;
      valid_out <= 0;

      // 清除影像記憶體
      for (i = 0; i < MAX_SIZE; i = i + 1)
      begin
        image_mem[i] <= 0;
      end

    end
    else
    begin

      // 第一階段：接收並儲存輸入資料
      if (valid_in && !input_done)
      begin
        image_mem[input_count] <= data_in;
        input_count <= input_count + 1;

        // 檢查是否接收完所有資料
        if (input_count == img_width * img_height - 1)
        begin
          input_done <= 1;
          output_row <= 0;
          output_col <= 0;
        end
      end

      // 第二階段：輸出3x3窗口
      else if (input_done)
      begin
        if (output_row < img_height && output_col < img_width)
        begin
          valid_out <= 1;

          // 輸出3x3窗口，中心在(output_row, output_col)
          data_out0 <= get_pixel(output_row - 1, output_col - 1); // 左上
          data_out1 <= get_pixel(output_row - 1, output_col);     // 上中
          data_out2 <= get_pixel(output_row - 1, output_col + 1); // 右上
          data_out3 <= get_pixel(output_row, output_col - 1);     // 左中
          data_out4 <= get_pixel(output_row, output_col);         // 中心
          data_out5 <= get_pixel(output_row, output_col + 1);     // 右中
          data_out6 <= get_pixel(output_row + 1, output_col - 1); // 左下
          data_out7 <= get_pixel(output_row + 1, output_col);     // 下中
          data_out8 <= get_pixel(output_row + 1, output_col + 1); // 右下

          // 更新輸出位置
          if (output_col == img_width - 1)
          begin
            output_col <= 0;
            output_row <= output_row + 1;
          end
          else
          begin
            output_col <= output_col + 1;
          end

        end
        else
        begin
          valid_out <= 0; // 所有窗口輸出完畢
        end
      end

      else
      begin
        valid_out <= 0;
      end
    end
  end

endmodule
