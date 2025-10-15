// conv_3x3.v
module conv_3x3(
    input clk,
    input rst_n,
    input valid_in,

    input signed [15:0] data_in0,
    input signed [15:0] data_in1,
    input signed [15:0] data_in2,
    input signed [15:0] data_in3,
    input signed [15:0] data_in4,
    input signed [15:0] data_in5,
    input signed [15:0] data_in6,
    input signed [15:0] data_in7,
    input signed [15:0] data_in8,

    input signed [15:0] weight0,
    input signed [15:0] weight1,
    input signed [15:0] weight2,
    input signed [15:0] weight3,
    input signed [15:0] weight4,
    input signed [15:0] weight5,
    input signed [15:0] weight6,
    input signed [15:0] weight7,
    input signed [15:0] weight8,

    output reg signed [15:0] data_out,
    output reg valid_out
  );

  // Stage 1: Input register
  reg signed [15:0] data_in0_q, data_in1_q, data_in2_q;
  reg signed [15:0] data_in3_q, data_in4_q, data_in5_q;
  reg signed [15:0] data_in6_q, data_in7_q, data_in8_q;
  reg signed [15:0] weight0_q, weight1_q, weight2_q;
  reg signed [15:0] weight3_q, weight4_q, weight5_q;
  reg signed [15:0] weight6_q, weight7_q, weight8_q;
  reg valid_in_q1;

  // Stage 2: Multiplier output
  reg signed [31:0] mult0, mult1, mult2;
  reg signed [31:0] mult3, mult4, mult5;
  reg signed [31:0] mult6, mult7, mult8;
  reg valid_in_q2;

  // Stage 3: Accumulator
  reg signed [31:0] mult_sum;
  reg valid_in_q3;

  // Stage 1: Register inputs and weights
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_in0_q <= 0;
      data_in1_q <= 0;
      data_in2_q <= 0;
      data_in3_q <= 0;
      data_in4_q <= 0;
      data_in5_q <= 0;
      data_in6_q <= 0;
      data_in7_q <= 0;
      data_in8_q <= 0;
      weight0_q <= 0;
      weight1_q <= 0;
      weight2_q <= 0;
      weight3_q <= 0;
      weight4_q <= 0;
      weight5_q <= 0;
      weight6_q <= 0;
      weight7_q <= 0;
      weight8_q <= 0;
      valid_in_q1 <= 0;
    end
    else
    begin
      data_in0_q <= data_in0;
      data_in1_q <= data_in1;
      data_in2_q <= data_in2;
      data_in3_q <= data_in3;
      data_in4_q <= data_in4;
      data_in5_q <= data_in5;
      data_in6_q <= data_in6;
      data_in7_q <= data_in7;
      data_in8_q <= data_in8;
      weight0_q <= weight0;
      weight1_q <= weight1;
      weight2_q <= weight2;
      weight3_q <= weight3;
      weight4_q <= weight4;
      weight5_q <= weight5;
      weight6_q <= weight6;
      weight7_q <= weight7;
      weight8_q <= weight8;
      valid_in_q1 <= valid_in;
    end
  end

  // Stage 2: Multiply
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      mult0 <= 0;
      mult1 <= 0;
      mult2 <= 0;
      mult3 <= 0;
      mult4 <= 0;
      mult5 <= 0;
      mult6 <= 0;
      mult7 <= 0;
      mult8 <= 0;
      valid_in_q2 <= 0;
    end
    else
    begin
      mult0 <= $signed(data_in0_q) * $signed(weight0_q);
      mult1 <= $signed(data_in1_q) * $signed(weight1_q);
      mult2 <= $signed(data_in2_q) * $signed(weight2_q);
      mult3 <= $signed(data_in3_q) * $signed(weight3_q);
      mult4 <= $signed(data_in4_q) * $signed(weight4_q);
      mult5 <= $signed(data_in5_q) * $signed(weight5_q);
      mult6 <= $signed(data_in6_q) * $signed(weight6_q);
      mult7 <= $signed(data_in7_q) * $signed(weight7_q);
      mult8 <= $signed(data_in8_q) * $signed(weight8_q);
      valid_in_q2 <= valid_in_q1;
    end
  end

  // Stage 3: Accumulate
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      mult_sum <= 0;
      valid_in_q3 <= 0;
    end
    else
    begin
      mult_sum <= mult0 + mult1 + mult2 + mult3 + mult4 + mult5 + mult6 + mult7 + mult8;
      valid_in_q3 <= valid_in_q2;
    end
  end

  // Stage 4: Output
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      data_out <= 0;
      valid_out <= 0;
    end
    else
    begin
      data_out <= mult_sum[23:8];
      valid_out <= valid_in_q3;
    end
  end

endmodule
