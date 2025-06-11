// pooling.v
module pooling (
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

    output reg signed [7:0] max_out,
    output reg valid_out
  );

  reg signed [7:0] pool_array [0:8];
  integer i;
  reg signed [7:0] max_val;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      max_out <= 0;
      valid_out <= 0;
    end
    else if (valid_in)
    begin
      pool_array[0] <= data_in0;
      pool_array[1] <= data_in1;
      pool_array[2] <= data_in2;
      pool_array[3] <= data_in3;
      pool_array[4] <= data_in4;
      pool_array[5] <= data_in5;
      pool_array[6] <= data_in6;
      pool_array[7] <= data_in7;
      pool_array[8] <= data_in8;

      max_val = data_in0;
      for (i = 1; i < 9; i = i + 1)
      begin
        if (pool_array[i] > max_val)
          max_val = pool_array[i];
      end

      max_out <= max_val;
      valid_out <= 1;
    end
    else
    begin
      valid_out <= 0;
    end
  end

endmodule
