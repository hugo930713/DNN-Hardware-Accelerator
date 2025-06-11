// window_buffer_3x3_2d.v
module window_buffer_3x3_2d (
  input clk,
  input rst_n,
  input valid_in,
  input signed [7:0] data_in,
  
  output signed [7:0] data_out0,
  output signed [7:0] data_out1,
  output signed [7:0] data_out2,
  output signed [7:0] data_out3,
  output signed [7:0] data_out4,
  output signed [7:0] data_out5,
  output signed [7:0] data_out6,
  output signed [7:0] data_out7,
  output signed [7:0] data_out8,
  
  output valid_out
);

  // 參數定義 - 針對8x8輸入影像
  parameter IMG_WIDTH = 8;
  parameter IMG_HEIGHT = 8;
  
  // 行緩衝器：儲存前兩行數據
  reg signed [7:0] line0[0:IMG_WIDTH-1];
  reg signed [7:0] line1[0:IMG_WIDTH-1];
  // line2是當前輸入行，不需要儲存
  
  // 計數器
  reg [$clog2(IMG_WIDTH)-1:0] col;
  reg [$clog2(IMG_HEIGHT)-1:0] row;
  
  // 滑動窗口暫存器
  reg signed [7:0] win_data[0:8];
  reg valid_out_reg;
  
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          // 重置所有計數器和控制信號
          row <= 0;
          col <= 0;
          valid_out_reg <= 0;
          
          // 清空滑動窗口
          for (i = 0; i < 9; i = i + 1) begin
              win_data[i] <= 0;
          end
          
          // 清空行緩衝器
          for (i = 0; i < IMG_WIDTH; i = i + 1) begin
              line0[i] <= 0;
              line1[i] <= 0;
          end
      end
      else begin
          if (valid_in) begin
              // 更新3x3滑動窗口
              if (row >= 2 && col >= 2) begin
                  // 窗口佈局：
                  // win_data[0] win_data[1] win_data[2]
                  // win_data[3] win_data[4] win_data[5]  
                  // win_data[6] win_data[7] win_data[8]
                  
                  win_data[0] <= line0[col-2];  // 上一行，左2
                  win_data[1] <= line0[col-1];  // 上一行，左1
                  win_data[2] <= line0[col];    // 上一行，當前
                  win_data[3] <= line1[col-2];  // 當前行-1，左2
                  win_data[4] <= line1[col-1];  // 當前行-1，左1
                  win_data[5] <= line1[col];    // 當前行-1，當前
                  win_data[6] <= (col >= 2) ? ((col == 2) ? line1[0] : line1[col-2]) : 8'd0;  // 當前輸入行，左2
                  win_data[7] <= (col >= 1) ? ((col == 1) ? line1[0] : line1[col-1]) : 8'd0;  // 當前輸入行，左1
                  win_data[8] <= data_in;       // 當前輸入像素
                  
                  valid_out_reg <= 1;
              end
              else begin
                  valid_out_reg <= 0;
              end
              
              // 更新行緩衝器和計數器
              if (col == IMG_WIDTH - 1) begin
                  // 一行結束，準備下一行
                  col <= 0;
                  if (row < IMG_HEIGHT - 1) begin
                      row <= row + 1;
                  end
                  
                  // 行緩衝器移位
                  for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                      line0[i] <= line1[i];
                      line1[i] <= (i == 0) ? data_in : line1[i]; // 當前像素儲存到line1的開頭
                  end
                  line1[0] <= data_in; // 儲存行尾像素
              end
              else begin
                  // 同一行內繼續
                  col <= col + 1;
                  
                  // 儲存當前像素到line1
                  line1[col] <= data_in;
              end
          end
          else begin
              // valid_in為0時，保持valid_out為0
              valid_out_reg <= 0;
          end
      end
  end
  
  // 輸出連接
  assign data_out0 = win_data[0];
  assign data_out1 = win_data[1];
  assign data_out2 = win_data[2];
  assign data_out3 = win_data[3];
  assign data_out4 = win_data[4];
  assign data_out5 = win_data[5];
  assign data_out6 = win_data[6];
  assign data_out7 = win_data[7];
  assign data_out8 = win_data[8];
  assign valid_out = valid_out_reg;

endmodule