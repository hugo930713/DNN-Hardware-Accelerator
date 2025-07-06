module window_buffer_3x3_2d_with_padding (
    input clk,
    input rst_n,
    input valid_in,
    input signed [7:0] data_in,
    input [7:0] img_width,
    input [7:0] img_height,
    input [1:0] padding_mode, // 00: no padding, 01: zero padding

    output reg signed [7:0] data_out0, data_out1, data_out2,
    output reg signed [7:0] data_out3, data_out4, data_out5,
    output reg signed [7:0] data_out6, data_out7, data_out8,
    output reg valid_out
  );
  parameter MAX_WIDTH = 256;

  reg signed [7:0] line0[0:MAX_WIDTH-1];
  reg signed [7:0] line1[0:MAX_WIDTH-1];
  reg signed [7:0] line2[0:MAX_WIDTH-1];
  reg [7:0] input_col, input_row;     // 輸入像素的座標
  reg [7:0] output_col, output_row;   // 輸出 window 的座標
  reg [7:0] total_inputs;             // 總輸入計數器
  reg input_finished;                 // 輸入完成旗標

  integer i;

  wire is_padding_mode_active;
  wire is_no_padding_mode_active;

  assign is_padding_mode_active = (padding_mode == 2'b01 && output_row < img_height);
  assign is_no_padding_mode_active = (padding_mode == 2'b00 && output_row < (img_height - 2));

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      input_col <= 0;
      input_row <= 0;
      output_col <= 0;
      output_row <= 0;
      total_inputs <= 0;
      valid_out <= 0;
      input_finished <= 0;

      for (i = 0; i < MAX_WIDTH; i = i + 1)
      begin
        line0[i] <= 0;
        line1[i] <= 0;
        line2[i] <= 0;
      end
      {data_out0, data_out1, data_out2,
       data_out3, data_out4, data_out5,
       data_out6, data_out7, data_out8} <= 0;
    end
    else
    begin
      valid_out <= 0;

      // [Stage 1] 處理輸入資料 (兩種模式通用)
      if (valid_in)
      begin
        // Line buffer shift (每行開始時進行shift)
        if (input_col == 0)
        begin
          for (i = 0; i < MAX_WIDTH; i = i + 1)
          begin
            line0[i] <= line1[i];
            line1[i] <= line2[i];
          end
        end
        // 寫入新資料
        line2[input_col] <= data_in;

        // 更新輸入座標
        if (input_col == img_width - 1)
        begin
          input_col <= 0;
          input_row <= input_row + 1;
        end
        else
        begin
          input_col <= input_col + 1;
        end
        total_inputs <= total_inputs + 1;
      end
      else if (!input_finished && total_inputs == img_width * img_height) // B: 輸入剛結束的第一拍
      begin
        input_finished <= 1; // 標記真實數據結束
        // 執行最後一次真實數據的移位
        for (i = 0; i < MAX_WIDTH; i = i + 1)
        begin
          line0[i] <= line1[i];
          line1[i] <= line2[i];
        end
      end
      else if (input_finished)
      begin
        for (i = 0; i < MAX_WIDTH; i = i + 1)
        begin
          line0[i] <= line1[i];
          line1[i] <= line2[i];
          line2[i] <= 0; // 將 line2 清空，相同於移入一行 0
        end
      end

      // [Stage 2] 產生輸出 window
      // --- Case 1: Zero Padding Mode (for Convolution) ---
      if (padding_mode == 2'b01)
      begin
        // 當有足夠的輸入資料時開始輸出
        if (total_inputs >= img_width + 1)  // 至少需要 1 行多 1 個像素
        begin
          // 計算當前應該輸出的 window 位置
          if (output_row < img_height && output_col < img_width)
          begin
            // 產生 3x3 window (以 output_row, output_col 為中心)
            // 上排 (row-1)
            if (output_row == 0)
            begin
              data_out0 <= (output_col == 0) ? 8'd0 : 8'd0;         // 左上角 padding
              data_out1 <= 8'd0;                                     // 上邊 padding
              data_out2 <= (output_col == img_width-1) ? 8'd0 : 8'd0; // 右上角 padding
            end
            else
            begin
              data_out0 <= (output_col == 0) ? 8'd0 : line0[output_col-1];
              data_out1 <= line0[output_col];
              data_out2 <= (output_col == img_width-1) ? 8'd0 : line0[output_col+1];
            end

            // 中排 (row) - 使用 line1
            data_out3 <= (output_col == 0) ? 8'd0 : line1[output_col-1];
            data_out4 <= line1[output_col];
            data_out5 <= (output_col == img_width-1) ? 8'd0 : line1[output_col+1];

            // 下排 (row+1)
            if (output_row == img_height-1)
            begin
              data_out6 <= (output_col == 0) ? 8'd0 : 8'd0;         // 左下角 padding
              data_out7 <= 8'd0;                                     // 下邊 padding
              data_out8 <= (output_col == img_width-1) ? 8'd0 : 8'd0; // 右下角 padding
            end
            else
            begin
              data_out6 <= (output_col == 0) ? 8'd0 : line2[output_col-1];
              data_out7 <= line2[output_col];
              if (output_col == img_width-1)
                data_out8 <= 8'd0;  // 右邊界 padding
              else if (output_col + 1 == input_col && valid_in)
                data_out8 <= data_in;  // 使用當前輸入值
              else
                data_out8 <= line2[output_col+1];  // 使用 line buffer 中的值
            end

            valid_out <= 1;

            // 更新輸出座標
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
      end

      // --- Case 2: No Padding Mode (for Pooling) ---
      else if (padding_mode == 2'b00)
      begin
        // 啟動條件更嚴格：需等 line0, line1, line2 都可能填滿真實數據後才開始
        // 第一個輸出窗口中心是(1,1)，需要讀到(2,2)的像素，即 2*width+3 個像素
        if (total_inputs >= (2 * img_width + 3)) // 修正: 至少需要 2 個完整行
        begin
          // 輸出維度比輸入維度小 2
          if (output_row < (img_height - 2) && output_col < (img_width - 2))
          begin
            // 直接從 line buffer 組成窗口，沒有任何 padding 判斷
            // 索引修正：輸出座標(0,0)對應輸入窗口(0,1,2)列
            data_out0 <= line0[output_col];
            data_out1 <= line0[output_col+1];
            data_out2 <= line0[output_col+2];

            data_out3 <= line1[output_col];
            data_out4 <= line1[output_col+1];
            data_out5 <= line1[output_col+2];

            data_out6 <= line2[output_col];
            data_out7 <= line2[output_col+1];
            data_out8 <= line2[output_col+2];

            valid_out <= 1;

            // 更新輸出座標，邊界為縮小後的維度
            if (output_col == (img_width - 3))
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
      end
    end
  end
endmodule
