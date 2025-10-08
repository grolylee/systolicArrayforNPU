

`timescale 1ns/1ps

module tb_bugSoftmax;

  // ---------------- Parameters ----------------
  localparam int N           = 4;     // ✅ test 4 phần tử
  localparam int BIT_WIDTH   = 16;
  localparam int NUM_INPUTS  = 3;     // 3 hàng input
  localparam     CLK_PERIOD  = 10;

  // ---------------- DUT I/O ----------------
  logic                           i_clk, i_rst, i_valid;
  logic signed [N-1:0][BIT_WIDTH-1:0]    i_data ;   // Q2.14 input
  logic        [N-1:0][BIT_WIDTH-1:0]    o_data ;   // unsigned Q2.14 output
  logic                           o_valid;

  // ---------------- DUT ----------------
  bugSoftmax32 #(
    .N(N),
    .BIT_WIDTH(BIT_WIDTH)
  ) dut (
    .i_clk  (i_clk),
    .i_rst  (i_rst),
    .i_valid(i_valid),
    .i_data (i_data),
    .o_data (o_data),
    .o_valid(o_valid)
  );

  // ---------------- Clock ----------------
  initial begin
    i_clk = 0;
    forever #(CLK_PERIOD/2) i_clk = ~i_clk;  // 100 MHz
  end

  // ---------------- Helpers ----------------
  function real q2_14_to_real(input signed [BIT_WIDTH-1:0] val);
    q2_14_to_real = val / 16384.0; // 2^14
  endfunction

  function real q0_16u_to_real(input [BIT_WIDTH-1:0] val);
    q0_16u_to_real = val / 65536.0; // unsigned Q2.14
  endfunction

  // ---------------- Stimulus ----------------
  int num_outputs = 0;

  initial begin
    // Reset
    i_rst   = 1;
    i_valid = 0;
    i_data  = '{default:0};
    repeat (3) @(posedge i_clk);
    i_rst = 0;

    // ---- Input row 0 (lấy 4 phần tử đầu) ----
    @(posedge i_clk);
    i_valid = 1;
    i_data = '{ 1892, 4779, -734, -10706 };
    $display(">>> Input accepted at t=%0t, row=0, vals={%0d,%0d,%0d,%0d} (real=%.3f,%.3f,%.3f,%.3f)",
             $time, i_data[0], i_data[1], i_data[2], i_data[3],
             q2_14_to_real(i_data[0]), q2_14_to_real(i_data[1]),
             q2_14_to_real(i_data[2]), q2_14_to_real(i_data[3]));

    // ---- Input row 1 ----
    @(posedge i_clk);
    i_data = '{ 1728, -4327, 15993, -1290 };
    $display(">>> Input accepted at t=%0t, row=1, vals={%0d,%0d,%0d,%0d} (real=%.3f,%.3f,%.3f,%.3f)",
             $time, i_data[0], i_data[1], i_data[2], i_data[3],
             q2_14_to_real(i_data[0]), q2_14_to_real(i_data[1]),
             q2_14_to_real(i_data[2]), q2_14_to_real(i_data[3]));

    // ---- Input row 2 ----
    @(posedge i_clk);
    i_data = '{ -11521, -4881, 7536, 4060 };
    $display(">>> Input accepted at t=%0t, row=2, vals={%0d,%0d,%0d,%0d} (real=%.3f,%.3f,%.3f,%.3f)",
             $time, i_data[0], i_data[1], i_data[2], i_data[3],
             q2_14_to_real(i_data[0]), q2_14_to_real(i_data[1]),
             q2_14_to_real(i_data[2]), q2_14_to_real(i_data[3]));

    // Ngừng bơm input
    @(posedge i_clk);
    i_valid = 0;

    // Chờ đủ 3 outputs rồi dừng
    wait (num_outputs == NUM_INPUTS);
    $display("Done test after %0d outputs at t=%0t", num_outputs, $time);
    $finish;
  end

  // ---------------- Monitor outputs ----------------
  always @(posedge i_clk) begin
    if (o_valid) begin
      $display("<<< Output received at t=%0t, row=%0d", $time, num_outputs);
      $display("   o_data[0]=%0d (real=%.6f)", o_data[0], q0_16u_to_real(o_data[0]));
      $display("   o_data[1]=%0d (real=%.6f)", o_data[1], q0_16u_to_real(o_data[1]));
      $display("   o_data[2]=%0d (real=%.6f)", o_data[2], q0_16u_to_real(o_data[2]));
      $display("   o_data[3]=%0d (real=%.6f)", o_data[3], q0_16u_to_real(o_data[3]));
      num_outputs++;
    end
  end

endmodule

