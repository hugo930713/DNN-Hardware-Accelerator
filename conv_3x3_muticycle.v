module conv3x3_multicycle (
  input clk,
  input rst_n,
  input valid_in,
  input signed [7:0] data_in0,
  input signed [7:0] data_in1,
  input signed [7:0] data_in2,
  input signed [7:0] data_in3,
  input signed [7:0] data_in4,
  input signed [7:0] data_in5,
  input signed [7:0] data_in6,
  input signed [7:0] data_in7,
  input signed [7:0] data_in8,
  output reg valid_out,
  output reg signed [15:0] data_out
);

  // Sobel-X Kernel:
  // [ 1  0 -1 ]
  // [ 1  0 -1 ]
  // [ 1  0 -1 ]

  reg [1:0] cycle_cnt;
  reg signed [15:0] acc;
  reg processing;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_cnt <= 0;
      acc <= 0;
      valid_out <= 0;
      data_out <= 0;
      processing <= 0;
    end else begin
      if (valid_in && !processing) begin
        processing <= 1;
        cycle_cnt <= 0;
        acc <= 0;
        valid_out <= 0;
      end else if (processing) begin
        case (cycle_cnt)
          2'd0: begin
            // 第一列: data_in0 * 1 + data_in1 * 0 + data_in2 * -1
            acc <= data_in0 - data_in2;
          end
          2'd1: begin
            // 第二列: acc += data_in3 * 1 + data_in4 * 0 + data_in5 * -1
            acc <= acc + data_in3 - data_in5;
          end
          2'd2: begin
            // 第三列: acc += data_in6 * 1 + data_in7 * 0 + data_in8 * -1
            acc <= acc + data_in6 - data_in8;
          end
        endcase

        if (cycle_cnt == 2'd2) begin
          valid_out <= 1;
          data_out <= acc;
          processing <= 0;
        end else begin
          cycle_cnt <= cycle_cnt + 1;
          valid_out <= 0;
        end
      end else begin
        valid_out <= 0;
      end
    end
  end
endmodule


