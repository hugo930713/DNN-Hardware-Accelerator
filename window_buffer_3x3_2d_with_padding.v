module window_buffer_3x3_2d_with_padding #(
    parameter IMG_WIDTH = 8,
    parameter IMG_HEIGHT = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    input [7:0] pixel_in,
    output reg valid_out,
    output reg signed [7:0] data_out0,
    output reg signed [7:0] data_out1,
    output reg signed [7:0] data_out2,
    output reg signed [7:0] data_out3,
    output reg signed [7:0] data_out4,
    output reg signed [7:0] data_out5,
    output reg signed [7:0] data_out6,
    output reg signed [7:0] data_out7,
    output reg signed [7:0] data_out8
);

  reg [7:0] linebuf1 [0:IMG_WIDTH-1];
  reg [7:0] linebuf2 [0:IMG_WIDTH-1];

  integer col_cnt;
  integer i;

  reg [7:0] shift_reg0 [0:2]; // current line shift reg (3 pixels)
  reg [7:0] shift_reg1 [0:2]; // linebuf1 shift reg
  reg [7:0] shift_reg2 [0:2]; // linebuf2 shift reg

  reg [15:0] pixel_count;  // 總輸入像素數計數，決定何時 valid_out

  reg [15:0] row_cnt;      // 當前是第幾列 pixel (0-based)

  // 初始化
  initial begin
    for(i=0; i<IMG_WIDTH; i=i+1) begin
      linebuf1[i] = 0;
      linebuf2[i] = 0;
    end
    for(i=0; i<3; i=i+1) begin
      shift_reg0[i] = 0;
      shift_reg1[i] = 0;
      shift_reg2[i] = 0;
    end
    col_cnt = 0;
    pixel_count = 0;
    row_cnt = 0;
    valid_out = 0;
  end

  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      col_cnt <= 0;
      pixel_count <= 0;
      row_cnt <= 0;
      valid_out <= 0;
      for(i=0; i<IMG_WIDTH; i=i+1) begin
        linebuf1[i] <= 0;
        linebuf2[i] <= 0;
      end
      for(i=0; i<3; i=i+1) begin
        shift_reg0[i] <= 0;
        shift_reg1[i] <= 0;
        shift_reg2[i] <= 0;
      end
    end else begin
      if(valid_in) begin
        // Update line buffers
        linebuf2[col_cnt] <= linebuf1[col_cnt];
        linebuf1[col_cnt] <= pixel_in;

        // Update shift registers (3 elements shift)
        // current line
        shift_reg0[0] <= shift_reg0[1];
        shift_reg0[1] <= shift_reg0[2];
        shift_reg0[2] <= pixel_in;

        // linebuf1
        shift_reg1[0] <= shift_reg1[1];
        shift_reg1[1] <= shift_reg1[2];
        shift_reg1[2] <= linebuf1[col_cnt];

        // linebuf2
        shift_reg2[0] <= shift_reg2[1];
        shift_reg2[1] <= shift_reg2[2];
        shift_reg2[2] <= linebuf2[col_cnt];

        // Column counter +1 (wrap)
        if(col_cnt == IMG_WIDTH-1) begin
          col_cnt <= 0;
          row_cnt <= row_cnt + 1;  // 每列結束，列數加1
        end else begin
          col_cnt <= col_cnt + 1;
        end

        pixel_count <= pixel_count + 1;
      end

      // valid_out 控制：
      // 至少讀取3列(0-based row_cnt >= 2)
      // 且 col_cnt >= 2(代表有連續3 pixel可以組成視窗)
      if (pixel_count >= (3*IMG_WIDTH) && row_cnt >= 2 && col_cnt >= 2 && valid_in) begin
        valid_out <= 1;

        // 對應3x3窗
        data_out0 <= shift_reg2[0];
        data_out1 <= shift_reg2[1];
        data_out2 <= shift_reg2[2];

        data_out3 <= shift_reg1[0];
        data_out4 <= shift_reg1[1];
        data_out5 <= shift_reg1[2];

        data_out6 <= shift_reg0[0];
        data_out7 <= shift_reg0[1];
        data_out8 <= shift_reg0[2];
      end else begin
        valid_out <= 0;
      end
    end
  end

endmodule
