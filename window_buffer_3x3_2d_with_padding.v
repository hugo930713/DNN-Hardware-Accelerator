//==============================================================================
// Window Buffer 3x3 with Padding - DNN Hardware Accelerator
//==============================================================================
// Description:
//   這個模組實現3x3滑動視窗緩衝器，支援零填充(zero padding)和無填充模式
//   用於CNN卷積運算和池化運算的資料預處理
//
// Features:
//   - 支援兩種padding模式: 00=no padding (for pooling), 01=zero padding (for conv)
//   - 串流處理: 邊接收輸入資料邊輸出3x3視窗
//   - 最大支援圖片尺寸: 255x255 (8-bit width/height)
//   - 資料格式: Q8.8 fixed-point (16-bit signed)
//   - Pipeline輸出: 提供多級暫存器降低時序壓力
//
// Parameters:
//   - clk: 系統時脈
//   - rst_n: 低態重置訊號
//   - valid_in: 輸入資料有效訊號
//   - data_in: 輸入像素資料 (Q8.8 格式)
//   - img_width/img_height: 圖片尺寸 (1~255)
//   - padding_mode: 填充模式 (00=no padding, 01=zero padding)
//
// Outputs:
//   - data_out0~8: 3x3視窗輸出 (左上到右下順序)
//     data_out0  data_out1  data_out2
//     data_out3  data_out4  data_out5
//     data_out6  data_out7  data_out8
//   - valid_out: 輸出資料有效訊號
//
//==============================================================================

module window_buffer_3x3_2d_with_padding (
    input clk,
    input rst_n,
    input valid_in,
    input signed [15:0] data_in,
    input [7:0] img_width,
    input [7:0] img_height,
    input [1:0] padding_mode, // 00: no padding, 01: zero padding

    output reg signed [15:0] data_out0, data_out1, data_out2,
    data_out3, data_out4, data_out5,
    data_out6, data_out7, data_out8,
    output reg valid_out
  );
  //============================================================================
  // 參數定義
  //============================================================================
  parameter MAX_WIDTH = 256;                          // Line buffer 最大寬度
  localparam IMG_DIM_WIDTH = 8;                       // 圖片尺寸位元寬度 (支援 1~255)
  localparam TOTAL_COUNTER_WIDTH = IMG_DIM_WIDTH * 2; // 總像素計數器位元寬度 (支援最高 255x255)
  localparam PADDING_NONE = 2'b00;                    // 無填充模式 (用於池化)
  localparam PADDING_ZERO = 2'b01;                    // 零填充模式 (用於卷積)

  //============================================================================
  // 內部暫存器和信號宣告
  //============================================================================
  // Line buffer: 儲存3行影像資料 (滑動視窗需要)
  reg signed [15:0] line0 [0:MAX_WIDTH-1];           // 第0行緩衝器 (最舊的一行)
  reg signed [15:0] line1 [0:MAX_WIDTH-1];           // 第1行緩衝器 (中間行)
  reg signed [15:0] line2 [0:MAX_WIDTH-1];           // 第2行緩衝器 (最新的一行)

  // 座標計數器
  reg [7:0] input_col, input_row;                     // 當前輸入像素座標
  reg [7:0] output_col, output_row;                   // 當前輸出視窗座標

  // 控制信號
  reg [TOTAL_COUNTER_WIDTH-1:0] total_inputs;        // 已接收的總像素數
  reg input_finished;                                 // 所有像素輸入完成旗標

  // 輔助信號
  integer i;                                          // 迴圈變數
  wire [TOTAL_COUNTER_WIDTH-1:0] total_pixel_count;  // 總像素數 (寬*高)
  assign total_pixel_count = img_width * img_height;

  //============================================================================
  // 主要邏輯: 輸入處理 + 視窗輸出
  //============================================================================
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      // 重置所有控制信號
      input_col <= 8'd0;
      input_row <= 8'd0;
      output_col <= 8'd0;
      output_row <= 8'd0;
      total_inputs <= {TOTAL_COUNTER_WIDTH{1'b0}};
      valid_out <= 1'b0;
      input_finished <= 1'b0;

      // 清空所有 line buffer
      for (i = 0; i < MAX_WIDTH; i = i + 1)
      begin
        line0[i] <= 16'sd0;
        line1[i] <= 16'sd0;
        line2[i] <= 16'sd0;
      end

      // 清空輸出
      {data_out0, data_out1, data_out2,
       data_out3, data_out4, data_out5,
       data_out6, data_out7, data_out8} <= {9{16'sd0}};
    end
    else
    begin
      // 預設輸出無效 (每個 cycle 都要重新判斷)
      valid_out <= 1'b0;

      //========================================================================
      // Stage 1: 輸入資料處理 (兩種模式通用)
      //========================================================================
      if (valid_in)
      begin
        // Line buffer 移位操作 (每行開始時進行)
        if (input_col == 8'd0)
        begin
          for (i = 0; i < MAX_WIDTH; i = i + 1)
          begin
            line0[i] <= line1[i];  // line0 ← line1 (舊資料)
            line1[i] <= line2[i];  // line1 ← line2 (中間資料)
          end
        end

        // 將新像素寫入當前行緩衝器
        line2[input_col] <= data_in;

        // 更新輸入座標 (列優先掃描)
        if (input_col == img_width - 1)
        begin
          input_col <= 8'd0;                    // 換行
          input_row <= input_row + 1'b1;       // 下一行
        end
        else
        begin
          input_col <= input_col + 1'b1;       // 同行下一個像素
        end

        // 總輸入計數器遞增
        total_inputs <= total_inputs + 1'b1;
      end
      else if (!input_finished && total_inputs == total_pixel_count)
      begin
        // 所有像素已輸入，執行最後一次 line buffer 移位
        // (確保最後兩行資料正確放到 line0 和 line1)
        for (i = 0; i < MAX_WIDTH; i = i + 1)
        begin
          line0[i] <= line1[i];
          line1[i] <= line2[i];
        end
        input_finished <= 1'b1; // 標記輸入完成，避免重複執行
      end

      //========================================================================
      // Stage 2: 產生 3x3 視窗輸出
      //========================================================================

      // Case 1: 零填充模式 (用於卷積運算)
      if (padding_mode == PADDING_ZERO)
      begin
        // 當有足夠的輸入資料時開始輸出
        if (total_inputs >= img_width + 1)  // 至少需要 1 行多 1 個像素
        begin
          // 計算當前應該輸出的 window 位置
          if (output_row < img_height && output_col < img_width)
          begin
            // 生成 3x3 window (以 output_row, output_col 為中心)
            // 上排 (row-1)
            if (output_row == 0)
            begin
              data_out0 <= 16'sd0;  // 左上角零填充
              data_out1 <= 16'sd0;  // 上邊零填充
              data_out2 <= 16'sd0;  // 右上角零填充
            end
            else
            begin
              data_out0 <= (output_col == 8'd0) ? 16'sd0 : line0[output_col-1];
              data_out1 <= line0[output_col];
              data_out2 <= (output_col == img_width-1) ? 16'sd0 : line0[output_col+1];
            end

            // 中排 (當前行) - 始終使用 line1
            data_out3 <= (output_col == 8'd0) ? 16'sd0 : line1[output_col-1];
            data_out4 <= line1[output_col];
            data_out5 <= (output_col == img_width-1) ? 16'sd0 : line1[output_col+1];

            // 下排 (row+1)
            if (output_row == img_height-1)
            begin
              data_out6 <= 16'sd0;  // 左下角零填充
              data_out7 <= 16'sd0;  // 下邊零填充
              data_out8 <= 16'sd0;  // 右下角零填充
            end
            else
            begin
              data_out6 <= (output_col == 8'd0) ? 16'sd0 : line2[output_col-1];
              data_out7 <= line2[output_col];
              if (output_col == img_width-1)
                data_out8 <= 16'sd0;  // 右邊界零填充
              else if (output_col + 1 == input_col && valid_in)
                data_out8 <= data_in;  // 使用當前輸入值 (即時資料)
              else
                data_out8 <= line2[output_col+1];  // 使用 line buffer 中的值
            end

            valid_out <= 1'b1;

            // 更新輸出座標 (列優先掃描)
            if (output_col == img_width - 1)
            begin
              output_col <= 8'd0;
              output_row <= output_row + 1'b1;
            end
            else
            begin
              output_col <= output_col + 1'b1;
            end
          end
        end
      end

      // Case 2: 無填充模式 (用於池化運算)
      else if (padding_mode == PADDING_NONE)
      begin
        // 兩種狀態：
        // (A) 邊收邊出：只能輸出「已填好」的 window
        // (B) 全部收完（input_finished）：直接把剩下的 window 倒完（drain）

        // (A) streaming 條件：至少 3 行、且 window 的右下角不會碰到「當拍」才剛寫入的 col
        if (!input_finished)
        begin
          if (input_row >= 2)
          begin
            // 只有當 (output_row <= input_row-2) 且 (output_col+2 < input_col) 才保證 line2 的資料已寫入可讀
            if ( (output_row < (input_row - 2)) ||
                 (output_row == (input_row - 2) && (output_col + 2) < input_col) )
            begin

              data_out0 <= line0[output_col    ];
              data_out1 <= line0[output_col + 1];
              data_out2 <= line0[output_col + 2];

              data_out3 <= line1[output_col    ];
              data_out4 <= line1[output_col + 1];
              data_out5 <= line1[output_col + 2];

              data_out6 <= line2[output_col    ];
              data_out7 <= line2[output_col + 1];
              data_out8 <= line2[output_col + 2];

              valid_out <= 1;

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
        // (B) drain：全圖已在 line* 中，按 (0,0)~ 掃到結束
        else
        begin
          if (output_row < (img_height - 2) && output_col < (img_width - 2))
          begin
            data_out0 <= line0[output_col    ];
            data_out1 <= line0[output_col + 1];
            data_out2 <= line0[output_col + 2];

            data_out3 <= line1[output_col    ];
            data_out4 <= line1[output_col + 1];
            data_out5 <= line1[output_col + 2];

            data_out6 <= line2[output_col    ];
            data_out7 <= line2[output_col + 1];
            data_out8 <= line2[output_col + 2];

            valid_out <= 1;

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

  //============================================================================
  // Pipeline 暫存器: 降低時序壓力，提升 timing closure
  //============================================================================
  reg [7:0] output_col_q;                                // output_col pipeline (1級)
  reg signed [15:0] data_out0_q1, data_out0_q2;         // data_out0 pipeline (2級)
  reg signed [15:0] data_out1_q1, data_out1_q2;         // data_out1 pipeline (2級)
  reg signed [15:0] data_out3_q1, data_out3_q2;         // data_out3 pipeline (2級)
  reg signed [15:0] data_out4_q1, data_out4_q2;         // data_out4 pipeline (2級)
  reg signed [15:0] data_out5_q1, data_out5_q2;         // data_out5 pipeline (2級)
  reg signed [15:0] data_out6_q1, data_out6_q2;         // data_out6 pipeline (2級)
  reg signed [15:0] data_out7_q1, data_out7_q2;         // data_out7 pipeline (2級)
  reg signed [15:0] data_out8_q1, data_out8_q2;         // data_out8 pipeline (2級)

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      output_col_q <= 0;
    else
      output_col_q <= output_col;
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out0_q1 <= 16'd0;
      data_out0_q2 <= 16'd0;
      data_out1_q1 <= 16'd0;
      data_out1_q2 <= 16'd0;
      data_out3_q1 <= 16'd0;
      data_out3_q2 <= 16'd0;
      data_out4_q1 <= 16'd0;
      data_out4_q2 <= 16'd0;
      data_out5_q1 <= 16'd0;
      data_out5_q2 <= 16'd0;
      data_out6_q1 <= 16'd0;
      data_out6_q2 <= 16'd0;
      data_out7_q1 <= 16'd0;
      data_out7_q2 <= 16'd0;
      data_out8_q1 <= 16'd0;
      data_out8_q2 <= 16'd0;
    end
    else
    begin
      data_out0_q1 <= data_out0;
      data_out0_q2 <= data_out0_q1;
      data_out1_q1 <= data_out1;
      data_out1_q2 <= data_out1_q1;
      data_out3_q1 <= data_out3;
      data_out3_q2 <= data_out3_q1;
      data_out4_q1 <= data_out4;
      data_out4_q2 <= data_out4_q1;
      data_out5_q1 <= data_out5;
      data_out5_q2 <= data_out5_q1;
      data_out6_q1 <= data_out6;
      data_out6_q2 <= data_out6_q1;
      data_out7_q1 <= data_out7;
      data_out7_q2 <= data_out7_q1;
      data_out8_q1 <= data_out8;
      data_out8_q2 <= data_out8_q1;
    end
  end

  reg signed [15:0] data_out2_q1, data_out2_q2, data_out2_q3; // data_out2 pipeline (3級，最關鍵路徑)

  // data_out2 特殊處理 (3級 pipeline，因為是最關鍵的時序路徑)
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out2_q1 <= 16'sd0;
      data_out2_q2 <= 16'sd0;
      data_out2_q3 <= 16'sd0;
    end
    else
    begin
      data_out2_q1 <= data_out2;
      data_out2_q2 <= data_out2_q1;
      data_out2_q3 <= data_out2_q2;
    end
  end

  //============================================================================
  // 輸出建議:
  // - 使用 data_out*_q2 給後級模組 (2級 pipeline)
  // - 使用 data_out2_q3 給後級模組 (3級 pipeline，最佳時序)
  // - 使用 output_col_q 給後級模組 (1級 pipeline)
  //============================================================================
endmodule
