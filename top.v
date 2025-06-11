// 修正版 top.v with padding support
module top (
    input clk,
    input rst_n,
    input valid_in,
    input signed [7:0] pixel_in,
    input [7:0] img_width,     // 圖像寬度
    input [7:0] img_height,    // 圖像高度
    input [1:0] padding_mode,  // 00: no padding, 01: zero padding, 10: edge padding

    output signed [7:0] dout,
    output valid_out,

    // Debug輸出
    output signed [15:0] conv_result,
    output signed [7:0] relu_result,
    output valid_conv_out,
    output valid_relu_out,
    // 新增：padding 後的 3x3 視窗輸出 (方便 debug)
    output signed [7:0] debug_win_out0,
    output signed [7:0] debug_win_out1,
    output signed [7:0] debug_win_out2,
    output signed [7:0] debug_win_out3,
    output signed [7:0] debug_win_out4,
    output signed [7:0] debug_win_out5,
    output signed [7:0] debug_win_out6,
    output signed [7:0] debug_win_out7,
    output signed [7:0] debug_win_out8,
    output valid_window_out // 方便 debug
  );

  // 第1級：帶padding的輸入window buffer
  wire signed [7:0] win_out0, win_out1, win_out2;
  wire signed [7:0] win_out3, win_out4, win_out5;
  wire signed [7:0] win_out6, win_out7, win_out8;
  wire valid_window;

  window_buffer_3x3_2d_with_padding input_win_buf (
                                      .clk(clk),
                                      .rst_n(rst_n),
                                      .valid_in(valid_in),
                                      .data_in(pixel_in),
                                      .img_width(img_width),
                                      .img_height(img_height),
                                      .padding_mode(padding_mode),
                                      .data_out0(win_out0), .data_out1(win_out1), .data_out2(win_out2),
                                      .data_out3(win_out3), .data_out4(win_out4), .data_out5(win_out5),
                                      .data_out6(win_out6), .data_out7(win_out7), .data_out8(win_out8),
                                      .valid_out(valid_window)
                                    );

  // 第2級：卷積 (使用您原有的conv_3x3模組)
  wire signed [15:0] conv_out;

  conv_3x3 conv (
             .clk(clk),
             .rst_n(rst_n),
             .valid_in(valid_window),
             .in_data0(win_out0), .in_data1(win_out1), .in_data2(win_out2),
             .in_data3(win_out3), .in_data4(win_out4), .in_data5(win_out5),
             .in_data6(win_out6), .in_data7(win_out7), .in_data8(win_out8),
             .weight0(8'sd1), .weight1(8'sd0), .weight2(-8'sd1),
             .weight3(8'sd1), .weight4(8'sd0), .weight5(-8'sd1),
             .weight6(8'sd1), .weight7(8'sd0), .weight8(-8'sd1),
             .out_data(conv_out),
             .valid_out(valid_conv_out)
           );

  // 第3級：ReLU
  wire signed [7:0] relu_out;

  relu relu_inst (
         .clk(clk),
         .rst_n(rst_n),
         .valid_in(valid_conv_out),
         .din(conv_out),
         .dout(relu_out),
         .valid_out(valid_relu_out)
       );

  // 第4級：特徵圖window buffer（為pooling準備）
  // 計算卷積後的特徵圖尺寸
  wire [7:0] feature_width, feature_height;

  // 根據padding模式計算特徵圖尺寸
  assign feature_width = (padding_mode == 2'b00) ? (img_width - 2) : img_width;   // no padding時縮小2
  assign feature_height = (padding_mode == 2'b00) ? (img_height - 2) : img_height;

  wire signed [7:0] pool_win0, pool_win1, pool_win2;
  wire signed [7:0] pool_win3, pool_win4, pool_win5;
  wire signed [7:0] pool_win6, pool_win7, pool_win8;
  wire valid_pool_in;

  window_buffer_3x3_2d_with_padding feature_win_buf (
                                      .clk(clk),
                                      .rst_n(rst_n),
                                      .valid_in(valid_relu_out),
                                      .data_in(relu_out),
                                      .img_width(feature_width),
                                      .img_height(feature_height),
                                      .padding_mode(2'b00),  // pooling通常不使用padding
                                      .data_out0(pool_win0), .data_out1(pool_win1), .data_out2(pool_win2),
                                      .data_out3(pool_win3), .data_out4(pool_win4), .data_out5(pool_win5),
                                      .data_out6(pool_win6), .data_out7(pool_win7), .data_out8(pool_win8),
                                      .valid_out(valid_pool_in)
                                    );

  // 第5級：Pooling
  wire signed [7:0] pool_out;
  wire valid_pool_out;

  pooling pool (
            .clk(clk),
            .rst_n(rst_n),
            .valid_in(valid_pool_in),
            .data_in0(pool_win0), .data_in1(pool_win1), .data_in2(pool_win2),
            .data_in3(pool_win3), .data_in4(pool_win4), .data_in5(pool_win5),
            .data_in6(pool_win6), .data_in7(pool_win7), .data_in8(pool_win8),
            .max_out(pool_out),
            .valid_out(valid_pool_out)
          );

  // 輸出分配
  assign conv_result = conv_out;
  assign relu_result = relu_out;
  assign dout = pool_out;
  assign valid_out = valid_pool_out;

  assign debug_win_out0 = win_out0;
  assign debug_win_out1 = win_out1;
  assign debug_win_out2 = win_out2;
  assign debug_win_out3 = win_out3;
  assign debug_win_out4 = win_out4;
  assign debug_win_out5 = win_out5;
  assign debug_win_out6 = win_out6;
  assign debug_win_out7 = win_out7;
  assign debug_win_out8 = win_out8;
  assign valid_window_out = valid_window;

endmodule
