module window_buffer_3x3_2d_with_padding (
    input clk,
    input rst_n,
    input valid_in,
    input signed [7:0] data_in,
    input [7:0] img_width,
    input [7:0] img_height,
    input [1:0] padding_mode, // 00: no padding, 01: zero padding, 10: edge padding

    output signed [7:0] data_out0, data_out1, data_out2,
    output signed [7:0] data_out3, data_out4, data_out5,
    output signed [7:0] data_out6, data_out7, data_out8,
    output valid_out
  );

  parameter MAX_WIDTH = 256;

  // 線緩衝器存儲圖像的三行數據
  reg signed [7:0] line0[0:MAX_WIDTH-1]; // 上一行
  reg signed [7:0] line1[0:MAX_WIDTH-1]; // 當前行
  reg signed [7:0] line2[0:MAX_WIDTH-1]; // 下一行

  // 輸入位置計數器
  reg [7:0] input_col;
  reg [7:0] input_row;
  reg [15:0] input_pixel_count;

  // 輸出位置計數器（卷積窗口位置）
  reg [7:0] output_col;
  reg [7:0] output_row;
  reg output_valid;

  // 輸出尺寸計算
  wire [7:0] output_width, output_height;
  assign output_width = (padding_mode == 2'b00) ? (img_width >= 2 ? img_width - 2 : 0) : img_width;
  assign output_height = (padding_mode == 2'b00) ? (img_height >= 2 ? img_height - 2 : 0) : img_height;

  // 狀態機
  reg [1:0] state;
  parameter FILLING = 0, READY = 1, OUTPUTTING = 2;

  // 輸出窗口寄存器
  reg signed [7:0] window_out[0:8];

  integer i;

  // 獲取帶邊界處理的像素值
  function signed [7:0] get_pixel_with_padding;
    input [7:0] row_idx;
    input [7:0] col_idx;
    input [7:0] output_row_local;
    input [1:0] pad_mode;

    reg signed [7:0] pixel_val;
    reg [7:0] safe_row, safe_col;
    begin
      // 處理邊界
      safe_row = row_idx;
      safe_col = col_idx;

      if (row_idx >= img_height || col_idx >= img_width ||
          (row_idx == 8'hFF) || (col_idx == 8'hFF))
      begin
        // 超出邊界
        case (pad_mode)
          2'b01:
            pixel_val = 8'd0; // 零填充
          2'b10:
          begin // 邊緣填充
            if (row_idx == 8'hFF)
              safe_row = 0;
            else if (row_idx >= img_height)
              safe_row = img_height - 1;

            if (col_idx == 8'hFF)
              safe_col = 0;
            else if (col_idx >= img_width)
              safe_col = img_width - 1;

            if (safe_row == output_row_local - 1)
              pixel_val = line0[safe_col];
            else if (safe_row == output_row_local)
              pixel_val = line1[safe_col];
            else if (safe_row == output_row_local + 1)
              pixel_val = line2[safe_col];
            else
              pixel_val = 8'd0;
          end
          default:
            pixel_val = 8'd0;
        endcase
      end
      else
      begin
        if (row_idx == output_row_local - 1)
          pixel_val = line0[col_idx];
        else if (row_idx == output_row_local)
          pixel_val = line1[col_idx];
        else if (row_idx == output_row_local + 1)
          pixel_val = line2[col_idx];
        else
          pixel_val = 8'd0;
      end

      get_pixel_with_padding = pixel_val;
    end
  endfunction

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      input_col <= 0;
      input_row <= 0;
      input_pixel_count <= 0;
      output_col <= 0;
      output_row <= 0;
      output_valid <= 0;
      state <= FILLING;

      for (i = 0; i < 9; i = i + 1)
      begin
        window_out[i] <= 0;
      end

      for (i = 0; i < MAX_WIDTH; i = i + 1)
      begin
        line0[i] <= 0;
        line1[i] <= 0;
        line2[i] <= 0;
      end
    end
    else
    begin
      case (state)
        FILLING:
        begin
          output_valid <= 0;

          if (valid_in)
          begin
            // 存儲輸入像素
            line1[input_col] <= data_in;
            input_pixel_count <= input_pixel_count + 1;

            // 更新輸入位置
            if (input_col >= img_width - 1)
            begin
              input_col <= 0;
              if (input_row < img_height - 1)
              begin
                input_row <= input_row + 1;
                // 移動線緩衝器
                for (i = 0; i < MAX_WIDTH; i = i + 1)
                begin
                  line0[i] <= line1[i];
                  line2[i] <= line1[i]; // 預設下一行
                end
              end
            end
            else
            begin
              input_col <= input_col + 1;
            end

            // 檢查是否可以開始輸出
            if (padding_mode == 2'b00)
            begin
              // 無填充模式：需要至少收集 width + 1 個像素
              if (input_row >= 2 && input_col >= img_width - 1)
                state <= READY;
              output_col <= 0;
              output_row <= 0;
            end
            else
            begin
              // 有填充模式：第一個像素就可以開始輸出
              state <= READY;
              output_col <= 0;
              output_row <= 0;
            end
          end
        end

        READY:
        begin
          // 準備第一個輸出窗口
          state <= OUTPUTTING;
          output_valid <= 1;

          // 生成3x3窗口（相對於output_row, output_col）
          case (padding_mode)
            2'b00:
            begin // 無填充
              // 窗口中心位於 (output_row+1, output_col+1)
              window_out[0] <= line0[output_col];
              window_out[1] <= line0[output_col + 1];
              window_out[2] <= line0[output_col + 2];
              window_out[3] <= line1[output_col];
              window_out[4] <= line1[output_col + 1];
              window_out[5] <= line1[output_col + 2];
              window_out[6] <= line2[output_col];
              window_out[7] <= line2[output_col + 1];
              window_out[8] <= line2[output_col + 2];
            end
            default:
            begin // 有填充
              // 窗口中心位於 (output_row, output_col)
              window_out[0] <= get_pixel_with_padding(output_row - 1, output_col - 1, output_row, padding_mode);
              window_out[1] <= get_pixel_with_padding(output_row - 1, output_col,     output_row, padding_mode);
              window_out[2] <= get_pixel_with_padding(output_row - 1, output_col + 1, output_row, padding_mode);
              window_out[3] <= get_pixel_with_padding(output_row,     output_col - 1, output_row, padding_mode);
              window_out[4] <= get_pixel_with_padding(output_row,     output_col,     output_row, padding_mode);
              window_out[5] <= get_pixel_with_padding(output_row,     output_col + 1, output_row, padding_mode);
              window_out[6] <= get_pixel_with_padding(output_row + 1, output_col - 1, output_row, padding_mode);
              window_out[7] <= get_pixel_with_padding(output_row + 1, output_col,     output_row, padding_mode);
              window_out[8] <= get_pixel_with_padding(output_row + 1, output_col + 1, output_row, padding_mode);
            end
          endcase
        end

        OUTPUTTING:
        begin
          if (valid_in)
          begin
            // 繼續接收輸入
            line1[input_col] <= data_in;
            input_pixel_count <= input_pixel_count + 1;

            // 更新輸入位置
            if (input_col >= img_width - 1)
            begin
              input_col <= 0;
              if (input_row < img_height - 1)
              begin
                input_row <= input_row + 1;
                // 移動線緩衝器
                for (i = 0; i < MAX_WIDTH; i = i + 1)
                begin
                  line0[i] <= line1[i];
                  // line2 在下一行填充時更新
                end
              end
            end
            else
            begin
              input_col <= input_col + 1;
            end
          end

          // 更新輸出位置
          if (output_col >= output_width - 1)
          begin
            output_col <= 0;
            if (output_row >= output_height - 1)
            begin
              output_valid <= 0; // 完成所有輸出
            end
            else
            begin
              output_row <= output_row + 1;
            end
          end
          else
          begin
            output_col <= output_col + 1;
          end

          // 生成下一個窗口
          if (output_valid)
          begin
            case (padding_mode)
              2'b00:
              begin // 無填充
                window_out[0] <= line0[output_col];
                window_out[1] <= line0[output_col + 1];
                window_out[2] <= line0[output_col + 2];
                window_out[3] <= line1[output_col];
                window_out[4] <= line1[output_col + 1];
                window_out[5] <= line1[output_col + 2];
                window_out[6] <= line2[output_col];
                window_out[7] <= line2[output_col + 1];
                window_out[8] <= line2[output_col + 2];
              end
              default:
              begin // 有填充
                window_out[0] <= get_pixel_with_padding(output_row - 1, output_col - 1, output_row, padding_mode);
                window_out[1] <= get_pixel_with_padding(output_row - 1, output_col,     output_row, padding_mode);
                window_out[2] <= get_pixel_with_padding(output_row - 1, output_col + 1, output_row, padding_mode);
                window_out[3] <= get_pixel_with_padding(output_row,     output_col - 1, output_row, padding_mode);
                window_out[4] <= get_pixel_with_padding(output_row,     output_col,     output_row, padding_mode);
                window_out[5] <= get_pixel_with_padding(output_row,     output_col + 1, output_row, padding_mode);
                window_out[6] <= get_pixel_with_padding(output_row + 1, output_col - 1, output_row, padding_mode);
                window_out[7] <= get_pixel_with_padding(output_row + 1, output_col,     output_row, padding_mode);
                window_out[8] <= get_pixel_with_padding(output_row + 1, output_col + 1, output_row, padding_mode);
              end
            endcase
          end
        end
      endcase
    end
  end

  // 輸出分配
  assign data_out0 = window_out[0];
  assign data_out1 = window_out[1];
  assign data_out2 = window_out[2];
  assign data_out3 = window_out[3];
  assign data_out4 = window_out[4];
  assign data_out5 = window_out[5];
  assign data_out6 = window_out[6];
  assign data_out7 = window_out[7];
  assign data_out8 = window_out[8];
  assign valid_out = output_valid;

endmodule
