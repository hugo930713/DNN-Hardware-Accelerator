`timescale 1ns/1ps

module top #(
  parameter IMG_WIDTH = 8,
  parameter IMG_HEIGHT = 8
)(
  input clk,
  input rst_n,

  input valid_in,           // 輸入 pixel 有效信號
  input [7:0] pixel_in,     // 輸入 pixel

  output valid_final_out,   // 最終輸出有效信號
  output [7:0] data_final_out  // 最終輸出資料
);

  // --- window buffer signals ---
  wire win_valid_out;
  wire signed [7:0] win_data_out0, win_data_out1, win_data_out2;
  wire signed [7:0] win_data_out3, win_data_out4, win_data_out5;
  wire signed [7:0] win_data_out6, win_data_out7, win_data_out8;

  // --- conv interface ---
  wire conv_valid_in;
  wire signed [7:0] conv_data_in0, conv_data_in1, conv_data_in2;
  wire signed [7:0] conv_data_in3, conv_data_in4, conv_data_in5;
  wire signed [7:0] conv_data_in6, conv_data_in7, conv_data_in8;
  wire conv_valid_out;
  wire signed [15:0] conv_data_out;

  // --- relu interface ---
  wire relu_valid_in;
  wire signed [7:0] relu_data_in;
  wire relu_valid_out;
  wire [7:0] relu_data_out;

  // --- pooling interface ---
  wire pool_valid_in;
  wire signed [7:0] pool_data_in0, pool_data_in1, pool_data_in2;
  wire signed [7:0] pool_data_in3, pool_data_in4, pool_data_in5;
  wire signed [7:0] pool_data_in6, pool_data_in7, pool_data_in8;
  wire pool_valid_out;
  wire signed [7:0] pool_data_out;

  // --- final output from pipeline controller ---
  wire valid_final_out_wire;
  wire [7:0] data_final_out_wire;

  // 1. window buffer
  window_buffer_3x3_2d_with_padding #(
    .IMG_WIDTH(IMG_WIDTH),
    .IMG_HEIGHT(IMG_HEIGHT)
  ) win_buf (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .pixel_in(pixel_in),

    .valid_out(win_valid_out),
    .data_out0(win_data_out0),
    .data_out1(win_data_out1),
    .data_out2(win_data_out2),
    .data_out3(win_data_out3),
    .data_out4(win_data_out4),
    .data_out5(win_data_out5),
    .data_out6(win_data_out6),
    .data_out7(win_data_out7),
    .data_out8(win_data_out8)
  );

  // 2. pipeline controller FSM
  pipeline_controller ctrl (
    .clk(clk),
    .rst_n(rst_n),

    .win_valid_out(win_valid_out),
    .data_in0(win_data_out0),
    .data_in1(win_data_out1),
    .data_in2(win_data_out2),
    .data_in3(win_data_out3),
    .data_in4(win_data_out4),
    .data_in5(win_data_out5),
    .data_in6(win_data_out6),
    .data_in7(win_data_out7),
    .data_in8(win_data_out8),

    .conv_valid_in(conv_valid_in),
    .conv_data_in0(conv_data_in0),
    .conv_data_in1(conv_data_in1),
    .conv_data_in2(conv_data_in2),
    .conv_data_in3(conv_data_in3),
    .conv_data_in4(conv_data_in4),
    .conv_data_in5(conv_data_in5),
    .conv_data_in6(conv_data_in6),
    .conv_data_in7(conv_data_in7),
    .conv_data_in8(conv_data_in8),
    .conv_valid_out(conv_valid_out),
    .conv_data_out(conv_data_out),

    .relu_valid_in(relu_valid_in),
    .relu_data_in(relu_data_in),
    .relu_valid_out(relu_valid_out),
    .relu_data_out(relu_data_out),

    .pool_valid_in(pool_valid_in),
    .pool_data_in0(pool_data_in0),
    .pool_data_in1(pool_data_in1),
    .pool_data_in2(pool_data_in2),
    .pool_data_in3(pool_data_in3),
    .pool_data_in4(pool_data_in4),
    .pool_data_in5(pool_data_in5),
    .pool_data_in6(pool_data_in6),
    .pool_data_in7(pool_data_in7),
    .pool_data_in8(pool_data_in8),
    .pool_valid_out(pool_valid_out),
    .pool_data_out(pool_data_out),

    .valid_final_out(valid_final_out_wire),
    .data_final_out(data_final_out_wire)
  );

  // 3. conv3x3 multicycle
  conv3x3_multicycle conv (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(conv_valid_in),
    .data_in0(conv_data_in0),
    .data_in1(conv_data_in1),
    .data_in2(conv_data_in2),
    .data_in3(conv_data_in3),
    .data_in4(conv_data_in4),
    .data_in5(conv_data_in5),
    .data_in6(conv_data_in6),
    .data_in7(conv_data_in7),
    .data_in8(conv_data_in8),
    .valid_out(conv_valid_out),
    .data_out(conv_data_out)
  );

  // 4. relu multicycle
  relu_multicycle relu (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(relu_valid_in),
    .data_in(relu_data_in),
    .valid_out(relu_valid_out),
    .data_out(relu_data_out)
  );

  // 5. pool multicycle
  pool_multicycle pool (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(pool_valid_in),
    .data_in0(pool_data_in0),
    .data_in1(pool_data_in1),
    .data_in2(pool_data_in2),
    .data_in3(pool_data_in3),
    .data_in4(pool_data_in4),
    .data_in5(pool_data_in5),
    .data_in6(pool_data_in6),
    .data_in7(pool_data_in7),
    .data_in8(pool_data_in8),
    .valid_out(pool_valid_out),
    .data_out(pool_data_out)
  );

  // output assignments
  assign valid_final_out = valid_final_out_wire;
  assign data_final_out = data_final_out_wire;

endmodule



