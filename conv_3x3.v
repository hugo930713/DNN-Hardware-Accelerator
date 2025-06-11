// con_3x3.v
module conv_3x3(
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

    input signed [7:0] weight0,
    input signed [7:0] weight1,
    input signed [7:0] weight2,
    input signed [7:0] weight3,
    input signed [7:0] weight4,
    input signed [7:0] weight5,
    input signed [7:0] weight6,
    input signed [7:0] weight7,
    input signed [7:0] weight8,

    output reg signed [15:0] data_out,
    output reg valid_out
  );

  reg signed [15:0] mult_sum;
  reg valid_in_d;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      mult_sum <= 0;
      valid_in_d <= 0;
    end
    else
    begin
      mult_sum <=
               $signed(data_in0) * $signed(weight0) +
               $signed(data_in1) * $signed(weight1) +
               $signed(data_in2) * $signed(weight2) +
               $signed(data_in3) * $signed(weight3) +
               $signed(data_in4) * $signed(weight4) +
               $signed(data_in5) * $signed(weight5) +
               $signed(data_in6) * $signed(weight6) +
               $signed(data_in7) * $signed(weight7) +
               $signed(data_in8) * $signed(weight8);
      valid_in_d <= valid_in;
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out <= 0;
      valid_out <= 0;
    end
    else
    begin
      data_out <= mult_sum;
      valid_out <= valid_in_d;
    end
  end

endmodule
