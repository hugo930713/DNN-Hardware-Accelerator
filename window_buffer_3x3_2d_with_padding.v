// window_buffer_3x3_2d_with_padding.v
module window_buffer_3x3_2d_with_padding (
    input clk,
    input rst_n,
    input valid_in,
    input signed [7:0] data_in,
    input [7:0] img_width,
    input [7:0] img_height,
    input [1:0] padding_mode, // 00: no padding, 01: zero padding, 10: edge padding
    output reg signed [7:0] data_out0, data_out1, data_out2,
    output reg signed [7:0] data_out3, data_out4, data_out5,
    output reg signed [7:0] data_out6, data_out7, data_out8,
    output reg valid_out
  );

  // 直接儲存整張影像然後逐一輸出視窗
  parameter MAX_SIZE = 256;
  reg signed [7:0] image_mem [0:MAX_SIZE-1];

  reg [15:0] input_count;          // 使用16位元以支援更大影像
  reg [7:0] output_row, output_col;
  reg input_done;
  reg [15:0] total_pixels;         // 總像素數

  integer i;

  // 根據位置和padding取得像素值
  function signed [7:0] get_pixel;
    input signed [8:0] row, col;    // 使用9位元有號數支援負數索引
    begin
      // 檢查邊界條件
      if (row < 0 || row >= img_height || col < 0 || col >= img_width)
      begin
        case (padding_mode)
          2'b00:
            get_pixel = 0;     // no padding - shouldn't happen
          2'b01:
            get_pixel = 0;     // zero padding
          2'b10:
          begin              // edge padding
            // 邊緣填充：將超出範圍的座標限制在合法範圍內
            if (row < 0)
              row = 0;
            else if (row >= img_height)
              row = img_height - 1;
            if (col < 0)
              col = 0;
            else if (col >= img_width)
              col = img_width - 1;
            get_pixel = image_mem[row * img_width + col];
          end
          default:
            get_pixel = 0;
        endcase
      end
      else
      begin
        // 正常像素存取
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
      total_pixels <= 0;

      // 清除影像記憶體
      for (i = 0; i < MAX_SIZE; i = i + 1)
      begin
        image_mem[i] <= 0;
      end
    end
    else
    begin
      // 計算總像素數
      total_pixels <= img_width * img_height;

      // 第一階段：接收並儲存輸入資料
      if (valid_in && !input_done)
      begin
        // 確保不會寫入超出範圍
        if (input_count < MAX_SIZE)
        begin
          image_mem[input_count] <= data_in;
        end
        input_count <= input_count + 1;

        // 檢查是否接收完所有資料
        if (input_count == total_pixels - 1)
        begin
          input_done <= 1;
          output_row <= 0;
          output_col <= 0;
        end
      end

      // 第二階段：輸出3x3視窗
      else if (input_done)
      begin
        // 根據padding_mode決定輸出範圍
        case (padding_mode)
          2'b00:
          begin // 無補零 - 輸出範圍縮小
            if (output_row >= 1 && output_row < img_height - 1 &&
                output_col >= 1 && output_col < img_width - 1)
            begin
              valid_out <= 1;
              // 輸出3x3視窗，中心在(output_row, output_col)
              data_out0 <= get_pixel(output_row - 1, output_col - 1);
              data_out1 <= get_pixel(output_row - 1, output_col);
              data_out2 <= get_pixel(output_row - 1, output_col + 1);
              data_out3 <= get_pixel(output_row, output_col - 1);
              data_out4 <= get_pixel(output_row, output_col);
              data_out5 <= get_pixel(output_row, output_col + 1);
              data_out6 <= get_pixel(output_row + 1, output_col - 1);
              data_out7 <= get_pixel(output_row + 1, output_col);
              data_out8 <= get_pixel(output_row + 1, output_col + 1);
            end
            else
            begin
              valid_out <= 0;
            end
          end

          default:
          begin // 補零或邊緣延伸 - 輸出完整範圍
            if (output_row < img_height && output_col < img_width)
            begin
              valid_out <= 1;
              // 輸出3x3視窗，中心在(output_row, output_col)
              data_out0 <= get_pixel(output_row - 1, output_col - 1);
              data_out1 <= get_pixel(output_row - 1, output_col);
              data_out2 <= get_pixel(output_row - 1, output_col + 1);
              data_out3 <= get_pixel(output_row, output_col - 1);
              data_out4 <= get_pixel(output_row, output_col);
              data_out5 <= get_pixel(output_row, output_col + 1);
              data_out6 <= get_pixel(output_row + 1, output_col - 1);
              data_out7 <= get_pixel(output_row + 1, output_col);
              data_out8 <= get_pixel(output_row + 1, output_col + 1);
            end
            else
            begin
              valid_out <= 0;
            end
          end
        endcase

        // 更新輸出位置（行優先掃描）
        if (output_row < img_height)
        begin
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
      end
      else
      begin
        valid_out <= 0;
      end
    end
  end

endmodule
