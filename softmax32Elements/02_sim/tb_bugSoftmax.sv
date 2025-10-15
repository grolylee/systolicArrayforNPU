

// `timescale 1ns/1ps

// module tb_bugSoftmax;

//   // ---------------- Parameters ----------------
//   localparam int N           = 4;     // ✅ test 4 phần tử
//   localparam int BIT_WIDTH   = 16;
//   localparam int NUM_INPUTS  = 3;     // 3 hàng input
//   localparam     CLK_PERIOD  = 10;

//   // ---------------- DUT I/O ----------------
//   logic                           i_clk, i_rst, i_valid;
//   logic signed [BIT_WIDTH-1:0]    i_data [N-1:0];   // Q2.14 input
//   logic        [BIT_WIDTH-1:0]    o_data [N-1:0];   // unsigned Q2.14 output
//   logic                           o_valid;

//   // ---------------- DUT ----------------
//   bugSoftmax32 #(
//     .N(N),
//     .BIT_WIDTH(BIT_WIDTH)
//   ) dut (
//     .i_clk  (i_clk),
//     .i_rst  (i_rst),
//     .i_valid(i_valid),
//     .i_data (i_data),
//     .o_data (o_data),
//     .o_valid(o_valid)
//   );

//   // ---------------- Clock ----------------
//   initial begin
//     i_clk = 0;
//     forever #(CLK_PERIOD/2) i_clk = ~i_clk;  // 100 MHz
//   end

//   // ---------------- Helpers ----------------
//   function real q2_14_to_real(input signed [BIT_WIDTH-1:0] val);
//     q2_14_to_real = val / 16384.0; // 2^14
//   endfunction

//   function real q0_16u_to_real(input [BIT_WIDTH-1:0] val);
//     q0_16u_to_real = val / 65536.0; // unsigned Q2.14
//   endfunction

//   // ---------------- Stimulus ----------------
//   int num_outputs = 0;

//   initial begin
//     // Reset
//     i_rst   = 1;
//     i_valid = 0;
//     i_data  = '{default:0};
//     repeat (3) @(posedge i_clk);
//     i_rst = 0;

//     // ---- Input row 0 (lấy 4 phần tử đầu) ----
//     @(posedge i_clk);
//     i_valid = 1;
//     i_data[0] = -32768;
//     i_data[1] = -32768;
//     i_data[2] = -32768;
//     i_data[3] = -32768;
//     $display(">>> Input accepted at t=%0t, row=0, vals={%0d,%0d,%0d,%0d} (real=%.3f,%.3f,%.3f,%.3f)",
//              $time, i_data[0], i_data[1], i_data[2], i_data[3],
//              q2_14_to_real(i_data[0]), q2_14_to_real(i_data[1]),
//              q2_14_to_real(i_data[2]), q2_14_to_real(i_data[3]));

//     // ---- Input row 1 ----
//     @(posedge i_clk);
//     i_data[0] = 1728;
//     i_data[1] = -4327;
//     i_data[2] = 15993;
//     i_data[3] = -1290;
//     $display(">>> Input accepted at t=%0t, row=1, vals={%0d,%0d,%0d,%0d} (real=%.3f,%.3f,%.3f,%.3f)",
//              $time, i_data[0], i_data[1], i_data[2], i_data[3],
//              q2_14_to_real(i_data[0]), q2_14_to_real(i_data[1]),
//              q2_14_to_real(i_data[2]), q2_14_to_real(i_data[3]));

//     // ---- Input row 2 ----
//     @(posedge i_clk);
//     i_data[0] = -11521;
//     i_data[1] =  -4881;
//     i_data[2] -= 7536;
//     i_data[3] = 4060;
//     $display(">>> Input accepted at t=%0t, row=2, vals={%0d,%0d,%0d,%0d} (real=%.3f,%.3f,%.3f,%.3f)",
//              $time, i_data[0], i_data[1], i_data[2], i_data[3],
//              q2_14_to_real(i_data[0]), q2_14_to_real(i_data[1]),
//              q2_14_to_real(i_data[2]), q2_14_to_real(i_data[3]));

//     // Ngừng bơm input
//     @(posedge i_clk);
//     i_valid = 0;

//     // Chờ đủ 3 outputs rồi dừng
//     wait (num_outputs == NUM_INPUTS);
//     $display("Done test after %0d outputs at t=%0t", num_outputs, $time);
//     $finish;
//   end

//   // ---------------- Monitor outputs ----------------
//   always @(posedge i_clk) begin
//     if (o_valid) begin
//       $display("<<< Output received at t=%0t, row=%0d", $time, num_outputs);
//       $display("   o_data[0]=%0d (real=%.6f)", o_data[0], q0_16u_to_real(o_data[0]));
//       $display("   o_data[1]=%0d (real=%.6f)", o_data[1], q0_16u_to_real(o_data[1]));
//       $display("   o_data[2]=%0d (real=%.6f)", o_data[2], q0_16u_to_real(o_data[2]));
//       $display("   o_data[3]=%0d (real=%.6f)", o_data[3], q0_16u_to_real(o_data[3]));
//       num_outputs++;
//     end
//   end

// endmodule



// // `timescale 1ns/1ns

// // module tb_bugSoftmax;

// //   // ---------------- Parameters ----------------
// //   localparam int N           = 32;     // 1 x 32 matrix
// //   localparam int BIT_WIDTH   = 16;     // Q2.14 format
// //   localparam int NUM_INPUTS  = 1;     // 1 row input
// //   localparam     CLK_PERIOD  = 10;    // 100 MHz clock

// //   // ---------------- DUT I/O ----------------
// //   logic                           i_clk, i_rst, i_valid;
// //   logic signed [BIT_WIDTH-1:0]    i_data [N-1:0];   // Q2.14 input
// //   logic        [BIT_WIDTH-1:0]    o_data [N-1:0];   // unsigned Q2.14 output
// //   logic                           o_valid;

// //   // ---------------- DUT ----------------
// //   bugSoftmax32 #(
// //     .N(N),
// //     .BIT_WIDTH(BIT_WIDTH)
// //   ) dut (
// //     .i_clk  (i_clk),
// //     .i_rst  (i_rst),
// //     .i_valid(i_valid),
// //     .i_data (i_data),
// //     .o_data (o_data),
// //     .o_valid(o_valid)
// //   );

// //   // ---------------- Clock ----------------
// //   initial begin
// //     i_clk = 0;
// //     forever #(CLK_PERIOD/2) i_clk = ~i_clk;  // 100 MHz
// //   end

// //   // ---------------- Helpers ----------------
// //   function real q2_14_to_real(input signed [BIT_WIDTH-1:0] val);
// //     q2_14_to_real = val / 16384.0; // 2^14
// //   endfunction

// //   function real q2_14u_to_real(input [BIT_WIDTH-1:0] val);
// //     q2_14u_to_real = val / 65536.0; // unsigned Q2.14 for softmax output
// //   endfunction

// //   // ---------------- Stimulus ----------------
// //   int num_outputs = 0;

// //   initial begin
// //     // Reset
// //     i_rst   = 1;
// //     i_valid = 0;
// //     i_data  = '{default:0};
// //     repeat (3) @(posedge i_clk);
// //     i_rst = 0;

// //     // ---- Input row 0 (all -2.0, fixed-point: -32768) ----
// //     @(posedge i_clk);
// //     i_valid = 1;
// // i_data = '{32479, 30877, 30782, 31819, 31941, 32219, 31368, 31719, 30714, 31062, 31798, 31062, 32679, 31129, 32761, 32144, 31467, 30823, 32129, 32239, 31349, 30665, 31771, 32505, 30817, 30753, 32177, 31661, 32438, 32737, 32077, 30657};

// //     $display(">>> Input accepted at t=%0t, row=0, vals={%0d,%0d,%0d,%0d,...} (real=%.3f,%.3f,%.3f,%.3f,...)",
// //              $time, i_data[0], i_data[1], i_data[2], i_data[3],
// //              q2_14_to_real(i_data[0]), q2_14_to_real(i_data[1]),
// //              q2_14_to_real(i_data[2]), q2_14_to_real(i_data[3]));

// //     // Ngừng bơm input
// //     @(posedge i_clk);
// //     i_valid = 0;

// //     // Chờ đủ 1 output rồi dừng
// //     wait (num_outputs == NUM_INPUTS);
// //     $display("Done test after outputs at t=%0t \n --------[PASS 3 TEST CASE]-------", num_outputs, $time);
// //     $finish;
// //   end

// //   // ---------------- Monitor outputs ----------------
// //   always @(posedge i_clk) begin
// //     if (o_valid) begin
// //       $display("<<< Output received at t=%0t, row=%0d", $time, num_outputs);
// //       for (int i = 0; i < N; i++) begin
// //         $display("   o_data[%0d]=%0d (real=%.6f)", i, o_data[i], q2_14u_to_real(o_data[i]));
// //       end
// //       num_outputs++;
// //     end
// //   end

// // endmodule







`timescale 1ns/1ps

module tb_bugSoftmax;

  // ---------------- Parameters ----------------
  localparam int N           = 4;     // ✅ test 4 phần tử
  localparam int BIT_WIDTH   = 16;
  localparam int NUM_INPUTS  = 3;     // 3 hàng input
  localparam     CLK_PERIOD  = 10;

  // ---------------- DUT I/O ----------------
  logic                           i_clk, i_rst, i_valid;
  logic signed [BIT_WIDTH-1:0]    i_data [N-1:0];   // Q2.14 input
  logic        [BIT_WIDTH-1:0]    o_data [N-1:0];   // unsigned Q2.14 output
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
