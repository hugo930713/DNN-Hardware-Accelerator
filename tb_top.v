`timescale 1ns/1ps

module tb_top;
  // Declare testbench input signals
  reg clk;
  reg rst_n;
  reg valid_in;
  reg signed [7:0] pixel_in;
  reg [7:0] img_width;
  reg [7:0] img_height;
  reg [1:0] padding_mode; // Padding mode for DUT

  // Declare DUT output signals
  wire signed [7:0] dout;
  wire valid_out;
  wire signed [15:0] conv_result;
  wire signed [7:0] relu_result;
  wire valid_conv_out;
  wire valid_relu_out;

  // Connect debug output ports from top.v
  wire signed [7:0] debug_win_out0;
  wire signed [7:0] debug_win_out1;
  wire signed [7:0] debug_win_out2;
  wire signed [7:0] debug_win_out3;
  wire signed [7:0] debug_win_out4;
  wire signed [7:0] debug_win_out5;
  wire signed [7:0] debug_win_out6;
  wire signed [7:0] debug_win_out7;
  wire signed [7:0] debug_win_out8;
  wire valid_window_out; // Indicates valid output from window_buffer

  // File operation variables
  integer f_out, f_in;
  // Loop counters and local variables for initial block
  integer i, j;
  integer current_row, current_col; // Moved from 'automatic' inside loop
  integer original_r, original_c;   // Moved from 'automatic' inside loop

  // Stage counters
  integer pixel_count = 0;
  integer conv_count = 0;
  integer relu_count = 0;
  integer pool_count = 0;
  integer window_count = 0; // Padded window output count

  // Define input image dimensions
  parameter IMAGE_DIM = 8;
  // Define padding mode for this test
  // 00: no padding, 01: zero padding, 10: edge padding
  parameter TEST_PADDING_MODE = 2'b01; // Example: Test zero padding

  // Calculate expected output dimensions based on TEST_PADDING_MODE and top.v logic
  // Convolution output dimensions (3x3 kernel, stride 1):
  // If input window buffer mode is no padding (00), output dimension is IMAGE_DIM - 2.
  // If input window buffer mode is zero/edge padding (01/10), output dimension is IMAGE_DIM.
  localparam CONV_OUTPUT_DIM = (TEST_PADDING_MODE == 2'b00) ? (IMAGE_DIM - 2) : IMAGE_DIM;

  // Pooling input dimension is the convolution output dimension (as calculated for feature_width/height in top.v)
  localparam POOL_INPUT_DIM = CONV_OUTPUT_DIM;
  // Pooling output dimension: Since feature_win_buf is hardcoded to no padding (2'b00), pooling output is POOL_INPUT_DIM - 2.
  localparam POOL_OUTPUT_DIM = POOL_INPUT_DIM - 2;

  // 根據window buffer的實際行為計算期望數量
  // Window buffer現在在row>=0 && col>=0時產生window，所以實際輸出是IMAGE_DIM*IMAGE_DIM
  localparam ACTUAL_WINDOW_DIM = IMAGE_DIM;  // 實際window輸出尺寸：8×8
  localparam ACTUAL_CONV_DIM = IMAGE_DIM;     // 實際卷積輸出尺寸：8×8
  localparam ACTUAL_POOL_DIM = ACTUAL_CONV_DIM - 2; // 實際pooling輸出尺寸：6×6

  // Matrices to store results (using actual output size)
  integer conv_matrix [0:ACTUAL_CONV_DIM-1][0:ACTUAL_CONV_DIM-1];
  integer relu_matrix [0:ACTUAL_CONV_DIM-1][0:ACTUAL_CONV_DIM-1];
  integer pool_matrix [0:ACTUAL_POOL_DIM-1][0:ACTUAL_POOL_DIM-1];

  // Matrix to store input image data (original values 0-255)
  reg signed [7:0] image_original [0:IMAGE_DIM-1][0:IMAGE_DIM-1];
  // Matrix to store input image data (converted to INT8)
  reg signed [7:0] image_int8 [0:IMAGE_DIM-1][0:IMAGE_DIM-1];
  // Matrix to store the *full* padded image (for display)
  integer padded_image_matrix [0:IMAGE_DIM+1][0:IMAGE_DIM+1]; // Max size for padding: IMAGE_DIM + 2 (for 1 pixel border on each side)

  // Calculate total expected output counts - 修正為實際數量
  wire [7:0] expected_window_count = ACTUAL_WINDOW_DIM * ACTUAL_WINDOW_DIM; // 實際window輸出數量
  wire [7:0] expected_conv_count = ACTUAL_CONV_DIM * ACTUAL_CONV_DIM;       // 實際卷積輸出數量
  wire [7:0] expected_pool_count = ACTUAL_POOL_DIM * ACTUAL_POOL_DIM;       // 實際pooling輸出數量

  // DUT (Design Under Test) Instantiation
  top uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .pixel_in(pixel_in),
        .img_width(img_width),
        .img_height(img_height),
        .padding_mode(padding_mode), // Pass testbench parameter to DUT
        .dout(dout),
        .valid_out(valid_out),
        .conv_result(conv_result),
        .relu_result(relu_result),
        .valid_conv_out(valid_conv_out),
        .valid_relu_out(valid_relu_out),
        // Connect debug output ports
        .debug_win_out0(debug_win_out0),
        .debug_win_out1(debug_win_out1),
        .debug_win_out2(debug_win_out2),
        .debug_win_out3(debug_win_out3),
        .debug_win_out4(debug_win_out4),
        .debug_win_out5(debug_win_out5),
        .debug_win_out6(debug_win_out6),
        .debug_win_out7(debug_win_out7),
        .debug_win_out8(debug_win_out8),
        .valid_window_out(valid_window_out)
      );

  // Clock generator (10ns period = 100MHz)
  always #5 clk = ~clk;

  // Monitor and display the Padded 3x3 Window
  always @(posedge clk)
  begin
    if (valid_window_out && window_count < expected_window_count)
    begin
      $display("\n--- Padded Window Output #%0d (Coord: %0d, %0d) ---", window_count + 1,
               window_count / ACTUAL_WINDOW_DIM, window_count % ACTUAL_WINDOW_DIM);
      $display("  %4d %4d %4d", debug_win_out0, debug_win_out1, debug_win_out2);
      $display("  %4d %4d %4d", debug_win_out3, debug_win_out4, debug_win_out5);
      $display("  %4d %4d %4d", debug_win_out6, debug_win_out7, debug_win_out8);

      window_count = window_count + 1;
    end
  end

  // Monitor and store Convolution results
  always @(posedge clk)
  begin
    if (valid_conv_out && conv_count < expected_conv_count)
    begin
      // Ensure index is not out of bounds
      if (conv_count / ACTUAL_CONV_DIM < ACTUAL_CONV_DIM && conv_count % ACTUAL_CONV_DIM < ACTUAL_CONV_DIM)
      begin
        conv_matrix[conv_count / ACTUAL_CONV_DIM][conv_count % ACTUAL_CONV_DIM] = conv_result;
        $display("Conv[%0d][%0d] = %0d (No.%0d)", conv_count / ACTUAL_CONV_DIM, conv_count % ACTUAL_CONV_DIM, conv_result, conv_count + 1);
        conv_count = conv_count + 1;
      end
      else
      begin
        $display("Error: conv_matrix index out of bounds! Count: %0d, Expected Dim: %0d", conv_count, ACTUAL_CONV_DIM);
      end
    end
  end

  // Monitor and store ReLU results
  always @(posedge clk)
  begin
    if (valid_relu_out && relu_count < expected_conv_count)
    begin
      // Ensure index is not out of bounds
      if (relu_count / ACTUAL_CONV_DIM < ACTUAL_CONV_DIM && relu_count % ACTUAL_CONV_DIM < ACTUAL_CONV_DIM)
      begin
        relu_matrix[relu_count / ACTUAL_CONV_DIM][relu_count % ACTUAL_CONV_DIM] = relu_result;
        $display("ReLU[%0d][%0d] = %0d (No.%0d)", relu_count / ACTUAL_CONV_DIM, relu_count % ACTUAL_CONV_DIM, relu_result, relu_count + 1);
        relu_count = relu_count + 1;
      end
      else
      begin
        $display("Error: relu_matrix index out of bounds! Count: %0d, Expected Dim: %0d", relu_count, ACTUAL_CONV_DIM);
      end
    end
  end

  // Monitor and store Pooling results
  always @(posedge clk)
  begin
    if (valid_out && pool_count < expected_pool_count)
    begin
      // Ensure index is not out of bounds
      if (pool_count / ACTUAL_POOL_DIM < ACTUAL_POOL_DIM && pool_count % ACTUAL_POOL_DIM < ACTUAL_POOL_DIM)
      begin
        pool_matrix[pool_count / ACTUAL_POOL_DIM][pool_count % ACTUAL_POOL_DIM] = dout;
        $display("Pool[%0d][%0d] = %0d (No.%0d)", pool_count / ACTUAL_POOL_DIM, pool_count % ACTUAL_POOL_DIM, dout, pool_count + 1);
        pool_count = pool_count + 1;
      end
      else
      begin
        $display("Error: pool_matrix index out of bounds! Count: %0d, Expected Dim: %0d", pool_count, ACTUAL_POOL_DIM);
      end
    end
  end

  initial
  begin
    // Initialize input signals
    clk = 0;
    rst_n = 0;
    valid_in = 0;
    pixel_in = 0;
    img_width = IMAGE_DIM;
    img_height = IMAGE_DIM;
    padding_mode = TEST_PADDING_MODE; // Set padding mode for this test

    // Reset sequence
    #20 rst_n = 1;
    $display("=== CNN Test Start (Padding Mode: %b) ===", TEST_PADDING_MODE);
    $display("Expected Outputs: Padded Window=%0dx%0d, Conv=%0dx%0d, Pool=%0dx%0d",
             ACTUAL_WINDOW_DIM, ACTUAL_WINDOW_DIM, ACTUAL_CONV_DIM, ACTUAL_CONV_DIM, ACTUAL_POOL_DIM, ACTUAL_POOL_DIM);

    // Read input image data
    f_in = $fopen("input_image.txt", "r");
    if (f_in == 0)
    begin
      $display("❌ Error: Cannot open input_image.txt. Please ensure the file exists and is readable.");
      $finish; // Terminate simulation if file cannot be opened
    end
    else
    begin
      // Read IMAGE_DIM x IMAGE_DIM image data from file
      for (i = 0; i < IMAGE_DIM; i = i + 1)
      begin
        for (j = 0; j < IMAGE_DIM; j = j + 1)
        begin
          if (!$feof(f_in))
          begin // Ensure not end of file
            $fscanf(f_in, "%d", image_original[i][j]);
            // Convert to signed INT8 immediately for display
            image_int8[i][j] = $signed(image_original[i][j]) - 8'sd128;
          end
          else
          begin
            $display("Warning: Fewer pixels than expected in input_image.txt at [%0d][%0d].", i, j);
            image_original[i][j] = 0; // Fill with default value if file ends
            image_int8[i][j] = 0;
          end
        end
      end
      $fclose(f_in);
    end

    // Display loaded input image (original values)
    $display("\n--- Input Image (Original 0-255, %0dx%0d) ---", IMAGE_DIM, IMAGE_DIM);
    for (i = 0; i < IMAGE_DIM; i = i + 1)
    begin
      for (j = 0; j < IMAGE_DIM; j = j + 1)
      begin
        $write("%4d ", image_original[i][j]);
      end
      $display("");
    end

    // Display loaded input image (INT8 values)
    $display("\n--- Input Image (Converted to INT8, %0dx%0d) ---", IMAGE_DIM, IMAGE_DIM);
    for (i = 0; i < IMAGE_DIM; i = i + 1)
    begin
      for (j = 0; j < IMAGE_DIM; j = j + 1)
      begin
        $write("%4d ", image_int8[i][j]);
      end
      $display("");
    end

    // Wait a few clock cycles for reset to propagate
    repeat(10) @(posedge clk);

    // Input pixels sequentially - row-major order
    $display("\n=== Starting Pixel Input to DUT ===");
    for (i = 0; i < IMAGE_DIM; i = i + 1)
    begin
      for (j = 0; j < IMAGE_DIM; j = j + 1)
      begin
        @(posedge clk);
        // Use the already converted INT8 value
        pixel_in = image_int8[i][j];
        valid_in = 1;
        pixel_count = pixel_count + 1;
        $display("Pixel[%0d][%0d] = %0d (Input Pixel #%0d)", i, j, pixel_in, pixel_count);
      end
    end

    // After all pixels are input, deassert valid_in
    @(posedge clk);
    valid_in = 0;

    // 多送足夠時脈，讓window buffer flush，確保所有結果都能推送出來
    // 估算最大pipeline深度：2層window buffer + conv + relu + pool，保守給 20 個時脈
    repeat(20) @(posedge clk);

    $display("=== Pixel Input Complete, Waiting for Results ===");
    $display("Waiting for Padded Window results... (Expected %0d)", expected_window_count);

    // 等待所有結果，但設置合理的超時
    repeat(1000) @(posedge clk);  // 等待1000個時鐘週期

    // 檢查結果
    $display("✅ Window Output Complete (%0d results)", window_count);
    $display("✅ Convolution Complete (%0d results)", conv_count);
    $display("✅ ReLU Complete (%0d results)", relu_count);
    $display("✅ Pooling Complete (%0d results)", pool_count);

    // Extra clock cycles to ensure all signals stabilize and final messages are output
    repeat(20) @(posedge clk);

    // --- Display and Write Final Matrices ---
    $display("\n--- Final Convolution Results (%0dx%0d) ---", ACTUAL_CONV_DIM, ACTUAL_CONV_DIM);
    f_out = $fopen("output_image_tb.txt", "w"); // Open file for writing results
    if (f_out == 0)
    begin
      $display("❌ Error: Cannot open output_image_tb.txt for writing.");
    end
    else
    begin
      $fwrite(f_out, "=== CNN Results (Padding Mode: %b) ===\n\n", TEST_PADDING_MODE);

      $fwrite(f_out, "--- Convolution Results (%0dx%0d) ---\n", ACTUAL_CONV_DIM, ACTUAL_CONV_DIM);
      for (i = 0; i < ACTUAL_CONV_DIM; i = i + 1)
      begin
        for (j = 0; j < ACTUAL_CONV_DIM; j = j + 1)
        begin
          $write("%6d ", conv_matrix[i][j]);
          $fwrite(f_out, "%6d ", conv_matrix[i][j]);
        end
        $display("");
        $fwrite(f_out, "\n");
      end

      $display("\n--- Final ReLU Results (%0dx%0d) ---", ACTUAL_CONV_DIM, ACTUAL_CONV_DIM);
      $fwrite(f_out, "\n--- ReLU Results (%0dx%0d) ---\n", ACTUAL_CONV_DIM, ACTUAL_CONV_DIM);
      for (i = 0; i < ACTUAL_CONV_DIM; i = i + 1)
      begin
        for (j = 0; j < ACTUAL_CONV_DIM; j = j + 1)
        begin
          $write("%6d ", relu_matrix[i][j]);
          $fwrite(f_out, "%6d ", relu_matrix[i][j]);
        end
        $display("");
        $fwrite(f_out, "\n");
      end

      $display("\n--- Final Pooling Results (%0dx%0d) ---", ACTUAL_POOL_DIM, ACTUAL_POOL_DIM);
      $fwrite(f_out, "\n--- Pooling Results (%0dx%0d) ---\n", ACTUAL_POOL_DIM, ACTUAL_POOL_DIM);
      for (i = 0; i < ACTUAL_POOL_DIM; i = i + 1)
      begin
        for (j = 0; j < ACTUAL_POOL_DIM; j = j + 1)
        begin
          $write("%6d ", pool_matrix[i][j]);
          $fwrite(f_out, "%6d ", pool_matrix[i][j]);
        end
        $display("");
        $fwrite(f_out, "\n");
      end

      $fclose(f_out);
    end

    // Display final results summary
    $display("\n=== Final Summary ===");
    $display("Total Input Pixels: %0d", pixel_count);
    $display("Total Padded Window Outputs: %0d (Expected %0d)", window_count, expected_window_count);
    $display("Total Convolution Outputs: %0d (Expected %0d)", conv_count, expected_conv_count);
    $display("Total ReLU Outputs: %0d (Expected %0d)", relu_count, expected_conv_count);
    $display("Total Pooling Outputs: %0d (Expected %0d)", pool_count, expected_pool_count);

    if (conv_count == expected_conv_count &&
        relu_count == expected_conv_count &&
        pool_count == expected_pool_count &&
        window_count == expected_window_count) // Check all counts
    begin
      $display("✅ Simulation complete. All output counts match expectations. Results saved to output_image_tb.txt");
    end
    else
    begin
      $display("❌ Simulation complete, but output counts do not match expectations!");
    end

    $finish; // Terminate simulation
  end

  // Simulation timeout mechanism
  initial
  begin
    #1000000; // 1 millisecond timeout
    $display("❌ Simulation timed out!");
    $finish; // Terminate simulation on timeout
  end

endmodule
