module relu_multicycle (
  input clk,
  input rst_n,
  input valid_in,
  input signed [7:0] data_in,
  output reg valid_out,
  output reg [7:0] data_out
);

  reg processing;
  reg [1:0] cycle_cnt;
  reg signed [7:0] data_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_out <= 0;
      cycle_cnt <= 0;
      processing <= 0;
      data_out <= 0;
      data_reg <= 0;
    end else begin
      if (valid_in && !processing) begin
        processing <= 1;
        cycle_cnt <= 0;
        data_reg <= data_in;
        valid_out <= 0;
      end else if (processing) begin
        cycle_cnt <= cycle_cnt + 1;
        if (cycle_cnt == 2'd2) begin
          // ReLU：輸出非負數
          if (data_reg < 0)
            data_out <= 0;
          else
            data_out <= data_reg[7:0];

          valid_out <= 1;
          processing <= 0;
        end else begin
          valid_out <= 0;
        end
      end else begin
        valid_out <= 0;
      end
    end
  end

endmodule

