// top.v
module top (
    input clk,
    input rst_n,
    input valid_in,
    input signed [15:0] pixel_in,
    input [7:0] img_width,
    input [7:0] img_height,
    input [1:0] padding_mode,  // 00: no padding, 01: zero padding, 10: edge padding

    output [31:0] dout_bus,
    output [1:0] valid_out_bus,

    // Debug bus輸出
    output [31:0] conv_result_bus,
    output [31:0] relu_result_bus,
    output [1:0] valid_conv_out_bus,
    output [1:0] valid_relu_out_bus,

    // padding 後的 3x3 視窗輸出
    // output signed [15:0] debug_win_out0,
    // output signed [15:0] debug_win_out1,
    // output signed [15:0] debug_win_out2,
    // output signed [15:0] debug_win_out3,
    // output signed [15:0] debug_win_out4,
    // output signed [15:0] debug_win_out5,
    // output signed [15:0] debug_win_out6,
    // output signed [15:0] debug_win_out7,
    // output signed [15:0] debug_win_out8,
    output valid_window_out,
    // Pooling debug outputs
    // output signed [15:0] debug_pool_win0,
    // output signed [15:0] debug_pool_win1,
    // output signed [15:0] debug_pool_win2,
    // output signed [15:0] debug_pool_win3,
    // output signed [15:0] debug_pool_win4,
    // output signed [15:0] debug_pool_win5,
    // output signed [15:0] debug_pool_win6,
    // output signed [15:0] debug_pool_win7,
    // output signed [15:0] debug_pool_win8,
    output valid_pool_window_out
  );

  // 第1級：帶padding的輸入window buffer
  wire signed [15:0] win_out0, win_out1, win_out2;
  wire signed [15:0] win_out3, win_out4, win_out5;
  wire signed [15:0] win_out6, win_out7, win_out8;
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

  // 第2級：卷積 (kernel1)
  wire signed [15:0] conv_out1;
  conv_3x3 conv1 (
             .clk(clk),
             .rst_n(rst_n),
             .valid_in(valid_window),
             .data_in0(win_out0), .data_in1(win_out1), .data_in2(win_out2),
             .data_in3(win_out3), .data_in4(win_out4), .data_in5(win_out5),
             .data_in6(win_out6), .data_in7(win_out7), .data_in8(win_out8),
             .weight0(16'sd1), .weight1(16'sd0), .weight2(-16'sd1),
             .weight3(16'sd1), .weight4(16'sd0), .weight5(-16'sd1),
             .weight6(16'sd1), .weight7(16'sd0), .weight8(-16'sd1),
             .data_out(conv_out1),
             .valid_out(valid_conv_out1)
           );

  // 第2級：卷積 (kernel2)
  wire signed [15:0] conv_out2;
  conv_3x3 conv2 (
             .clk(clk),
             .rst_n(rst_n),
             .valid_in(valid_window),
             .data_in0(win_out0), .data_in1(win_out1), .data_in2(win_out2),
             .data_in3(win_out3), .data_in4(win_out4), .data_in5(win_out5),
             .data_in6(win_out6), .data_in7(win_out7), .data_in8(win_out8),
             .weight0(16'sd1), .weight1(16'sd1), .weight2(16'sd1),
             .weight3(16'sd0), .weight4(16'sd0), .weight5(-16'sd0),
             .weight6(-16'sd1), .weight7(-16'sd1), .weight8(-16'sd1),
             .data_out(conv_out2),
             .valid_out(valid_conv_out2)
           );

  // 第3級：ReLU (kernel1)
  wire signed [15:0] relu_out1;
  relu relu1 (
         .clk(clk),
         .rst_n(rst_n),
         .valid_in(valid_conv_out1),
         .data_in(conv_out1),
         .data_out(relu_out1),
         .valid_out(valid_relu_out1)
       );

  // 第3級：ReLU (kernel2)
  wire signed [15:0] relu_out2;
  relu relu2 (
         .clk(clk),
         .rst_n(rst_n),
         .valid_in(valid_conv_out2),
         .data_in(conv_out2),
         .data_out(relu_out2),
         .valid_out(valid_relu_out2)
       );

  // 第4級：feature window buffer (kernel1)
  wire signed [15:0] feature_win1_0, feature_win1_1, feature_win1_2;
  wire signed [15:0] feature_win1_3, feature_win1_4, feature_win1_5;
  wire signed [15:0] feature_win1_6, feature_win1_7, feature_win1_8;
  wire valid_feature_win1;
  window_buffer_3x3_2d_with_padding feature_win_buf1 (
                                      .clk(clk),
                                      .rst_n(rst_n),
                                      .valid_in(valid_relu_out1),
                                      .data_in(relu_out1),
                                      .img_width(img_width),
                                      .img_height(img_height),
                                      .padding_mode(2'b00), // Pooling不需padding
                                      .data_out0(feature_win1_0), .data_out1(feature_win1_1), .data_out2(feature_win1_2),
                                      .data_out3(feature_win1_3), .data_out4(feature_win1_4), .data_out5(feature_win1_5),
                                      .data_out6(feature_win1_6), .data_out7(feature_win1_7), .data_out8(feature_win1_8),
                                      .valid_out(valid_feature_win1)
                                    );

  // 第4級：feature window buffer (kernel2)
  wire signed [15:0] feature_win2_0, feature_win2_1, feature_win2_2;
  wire signed [15:0] feature_win2_3, feature_win2_4, feature_win2_5;
  wire signed [15:0] feature_win2_6, feature_win2_7, feature_win2_8;
  wire valid_feature_win2;
  window_buffer_3x3_2d_with_padding feature_win_buf2 (
                                      .clk(clk),
                                      .rst_n(rst_n),
                                      .valid_in(valid_relu_out2),
                                      .data_in(relu_out2),
                                      .img_width(img_width),
                                      .img_height(img_height),
                                      .padding_mode(2'b00), // Pooling不需padding
                                      .data_out0(feature_win2_0), .data_out1(feature_win2_1), .data_out2(feature_win2_2),
                                      .data_out3(feature_win2_3), .data_out4(feature_win2_4), .data_out5(feature_win2_5),
                                      .data_out6(feature_win2_6), .data_out7(feature_win2_7), .data_out8(feature_win2_8),
                                      .valid_out(valid_feature_win2)
                                    );

  // 第5級：Pooling (kernel1)
  wire signed [15:0] pool_out1;
  wire valid_pool_out1;
  pooling pool1 (
            .clk(clk),
            .rst_n(rst_n),
            .valid_in(valid_feature_win1),
            .data_in0(feature_win1_0), .data_in1(feature_win1_1), .data_in2(feature_win1_2),
            .data_in3(feature_win1_3), .data_in4(feature_win1_4), .data_in5(feature_win1_5),
            .data_in6(feature_win1_6), .data_in7(feature_win1_7), .data_in8(feature_win1_8),
            .max_out(pool_out1),
            .valid_out(valid_pool_out1)
          );

  // 第5級：Pooling (kernel2)
  wire signed [15:0] pool_out2;
  wire valid_pool_out2;
  pooling pool2 (
            .clk(clk),
            .rst_n(rst_n),
            .valid_in(valid_feature_win2),
            .data_in0(feature_win2_0), .data_in1(feature_win2_1), .data_in2(feature_win2_2),
            .data_in3(feature_win2_3), .data_in4(feature_win2_4), .data_in5(feature_win2_5),
            .data_in6(feature_win2_6), .data_in7(feature_win2_7), .data_in8(feature_win2_8),
            .max_out(pool_out2),
            .valid_out(valid_pool_out2)
          );

  // 輸出分配（Verilog-2001 bus型態，雙 kernel）
  assign conv_result_bus = {conv_out2, conv_out1};
  assign relu_result_bus = {relu_out2, relu_out1};
  assign dout_bus = {pool_out2, pool_out1};
  assign valid_out_bus = {valid_pool_out2, valid_pool_out1};

  assign valid_window_out = valid_window;

  assign valid_conv_out_bus = {valid_conv_out2, valid_conv_out1};
  assign valid_relu_out_bus = {valid_relu_out2, valid_relu_out1};

  // assign debug_win_out0 = win_out0;
  // assign debug_win_out1 = win_out1;
  // assign debug_win_out2 = win_out2;
  // assign debug_win_out3 = win_out3;
  // assign debug_win_out4 = win_out4;
  // assign debug_win_out5 = win_out5;
  // assign debug_win_out6 = win_out6;
  // assign debug_win_out7 = win_out7;
  // assign debug_win_out8 = win_out8;

  // // Pooling debug outputs (kernel1)
  // assign debug_pool_win0 = feature_win1_0;
  // assign debug_pool_win1 = feature_win1_1;
  // assign debug_pool_win2 = feature_win1_2;
  // assign debug_pool_win3 = feature_win1_3;
  // assign debug_pool_win4 = feature_win1_4;
  // assign debug_pool_win5 = feature_win1_5;
  // assign debug_pool_win6 = feature_win1_6;
  // assign debug_pool_win7 = feature_win1_7;
  // assign debug_pool_win8 = feature_win1_8;
  // assign valid_pool_window_out = valid_feature_win1;

endmodule
