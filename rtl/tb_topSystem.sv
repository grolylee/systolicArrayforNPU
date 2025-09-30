// `timescale 1ns / 1ps

// module tb_topSystem;

//     logic i_clk;
//     logic i_rst;
//     logic i_start;
//     logic o_validResult;

//     int num_pass = 0;
//     int num_fail = 0;

//     // DUT
//     topSystem dut (
//         .i_clk(i_clk),
//         .i_rst(i_rst),
//         .i_start(i_start),
//         .o_valid(o_validResult)
//     );

//     // Clock generation
//     initial i_clk = 0;
//     always #5 i_clk = ~i_clk;

//     // Task in ma trận A
//     task print_matrixA;
//         $display("Input Matrix A:");
//         for (int i = 0; i < 32; i++) begin
//             for (int j = 0; j < 32; j++) begin
//                 $write("%0d ", dut.u_bram_fsm.o_matrixA[i][j]);
//             end
//             $write("\n");
//         end
//     endtask

//     // Task in ma trận B
//     task print_matrixB;
//         $display("Input Matrix B:");
//         for (int i = 0; i < 32; i++) begin
//             for (int j = 0; j < 32; j++) begin
//                 $write("%0d ", dut.u_bram_fsm.o_matrixB[i][j]);
//             end
//             $write("\n");
//         end
//     endtask

//     // Task in kết quả softmax (row 0)
//     task print_output_result;
//         $display("Output Softmax (Row 0):");
//         for (int i = 0; i < 32; i++) begin
//             $display("softmax[%0d] = %0d (≈ %0.6f)",
//                      i,
//                      dut.o_softmax[i],
//                      $itor(dut.o_softmax[i]) / 65536.0);
//         end
//     endtask

//     task print_matrixC_row0;
//         $display("Output Matrix C (Row 0) - trước Quantizer:");
//         for (int j = 0; j < 32; j++) begin
//             $display("C[0][%0d] = %0d", j, dut.o_cScaleClip[0][j]);
//         end
//     endtask

//     // Task ghi kết quả softmax vào .coe file
//     task write_softmax_coe;
//         integer file;
//         file = $fopen("softmax_output_row0.coe", "w");
//         if (file) begin
//             $fwrite(file, "memory_initialization_radix=10;\n");
//             $fwrite(file, "memory_initialization_vector=\n");
//             for (int i = 0; i < 32; i++) begin
//                 $fwrite(file, "%0d", dut.o_softmax[i]);
//                 if (i != 31) $fwrite(file, ", ");
//                 else         $fwrite(file, ";\n");
//             end
//             $fclose(file);
//             $display("[STATUS] softmax_output_row0.coe written.");
//             num_pass++;
//         end else begin
//             $display("[FAIL] Could not write softmax_output_row0.coe.");
//             num_fail++;
//         end
//     endtask

//     // Task kiểm tra input A & B không chứa X
//     task check_matrix_input;
//         bit pass = 1;
//         for (int i = 0; i < 32; i++) begin
//             for (int j = 0; j < 32; j++) begin
//                 if (dut.u_bram_fsm.o_matrixA[i][j] === 'x ||
//                     dut.u_bram_fsm.o_matrixB[i][j] === 'x) begin
//                     $display("[FAIL] Detected X at A[%0d][%0d] or B[%0d][%0d]", i, j, i, j);
//                     pass = 0;
//                 end
//             end
//         end
//         if (pass) begin
//             $display("[PASS] Input A and B valid (no X detected).");
//             num_pass++;
//         end else begin
//             $display("[FAIL] Input A or B contains undefined values.");
//             num_fail++;
//         end
//     endtask

//     // Stimulus chính
//     initial begin
//         i_rst   = 1;
//         i_start = 0;
//         #20;
//         i_rst = 0;
//         #10;
//         i_start = 1;
//         $display("Time %0t | 🔔 i_start asserted", $time);
//         #100;
//         i_start = 0;

//         // Chờ o_validResult hoặc timeout
//         fork
//             begin
//                 wait (o_validResult);
//                 $display("Time %0t | 🎯 o_validResult asserted", $time);
//             end
//             begin
//                 #1_000_000;
//                 $display("[ERROR] Simulation timed out waiting for o_validResult!");
//                 num_fail++;
//                 $finish();
//             end
//         join_any

//         if (o_validResult) begin
//             print_matrixA();
//             print_matrixB();
//             print_output_result();

// print_matrixC_row0();

//             check_matrix_input();
//             write_softmax_coe();

//             $display("\n========== VERIFICATION ==========");
//             $display("TEST PASS: %0d", num_pass);
//             $display("TEST FAIL: %0d", num_fail);
//             if (num_fail == 0)
//                 $display("[FINAL RESULT] ✅ ALL TEST PASS!");
//             else
//                 $display("[FINAL RESULT] ❌ FAIL DETECTED!");
//         end else begin
//             $display("[ERROR] o_validResult was not asserted!");
//         end

//         $finish();
//     end

//     // ====================================================
//     // DEBUG MONITORS (đặt cuối để in toàn bộ pipeline)
//     // ====================================================
//     always_ff @(posedge i_clk) begin
//         if (dut.bramDone)
//             $display("Time %0t | ✅ bramDone", $time);

//         if (dut.i_validScaleClip)
//             $display("Time %0t | ✅ systolicArray done (i_validScaleClip)", $time);

//         if (dut.o_validScaleClip)
//             $display("Time %0t | ✅ quantizer output valid", $time);

//         if (dut.flatten_done)
//             $display("Time %0t | ✅ flatten_done, start write to BRAM_out", $time);

// //        if (dut.rd_start && dut.rd_counter < 32)
// //            $display("Time %0t | 📥 Read[%0d] -> rd_addr=%0d, rd_data=%0h",
// //                     $time, dut.rd_counter, dut.rd_addr, dut.rd_data);

//         if (dut.softmax_start)
//             $display("Time %0t | 🚀 softmax_start=1", $time);

//         if (dut.softmax_valid)
//             $display("Time %0t | 🎯 softmax_valid=1, o_softmax[0]=%0d (≈ %0.6f)",
//                      $time, dut.o_softmax[0], $itor(dut.o_softmax[0]) / 65536.0);
//     end

// endmodule




`timescale 1ns/1ns

module tb_topSystem;

  // Clock & Reset
  logic i_clk;
  logic i_rst;
  logic i_start;

  // Probe BRAM outputs
  logic [4:0]  tb_probe_addr;
  logic [15:0] tb_probe_doutb;

  // Done flag từ DUT
  logic o_valid;

  // Cycle counter (để đo latency)
  int tb_cycle_cnt;
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst)
      tb_cycle_cnt <= 0;
    else
      tb_cycle_cnt <= tb_cycle_cnt + 1;
  end

  // Instance DUT
  topSystem dut (
    .i_clk       (i_clk),
    .i_rst       (i_rst),
    .i_start     (i_start),
    .o_valid     (o_valid),
    .i_probe_addr(tb_probe_addr),
    .o_probe_doutb(tb_probe_doutb)
  );

  // Clock gen
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk; // 100MHz
  end

  // Task: in ma trận A
  task print_matrixA;
    int i, j;
    begin
      $display("\n========== INPUT MATRIX A ==========");
      for (i = 0; i < 32; i++) begin
        $write("Row %0d: ", i);
        for (j = 0; j < 32; j++) begin
          $write("%0d ", dut.i_a[i][j]);
        end
        $write("\n");
      end
    end
  endtask

  // Task: in ma trận B
  task print_matrixB;
    int i, j;
    begin
      $display("\n========== INPUT MATRIX B ==========");
      for (i = 0; i < 32; i++) begin
        $write("Row %0d: ", i);
        for (j = 0; j < 32; j++) begin
          $write("%0d ", dut.i_b[i][j]);
        end
        $write("\n");
      end
    end
  endtask

  // Task: đọc dữ liệu softmax từ BRAM
// Task: đọc dữ liệu softmax từ BRAM
task read_softmax_outputs;
  real val_real, sum_real;
  int i;
  begin
    sum_real = 0.0;

    // Đợi DUT báo xong ghi BRAM
    @(posedge o_valid);
    repeat (3) @(posedge i_clk);  // chờ thêm vài cycle an toàn

    // Prefetch lần đầu
    tb_probe_addr = 0;
    @(posedge i_clk);

    // Đọc pipeline dịch ra đúng 32 giá trị
    for (i = 0; i < 33; i++) begin
      tb_probe_addr = i+1; // cấp địa chỉ kế tiếp
      @(posedge i_clk);

      if (i >= 1) begin
        val_real  = tb_probe_doutb / 65536.0;
        sum_real += val_real;
        $display("[Cycle=%0d | Time=%0t] SOFTMAX[%0d] = %0d (%.6f)",
                 tb_cycle_cnt, $time, i-1, tb_probe_doutb, val_real);
      end
    end

    $display("----------------------------------------------");
    $display("[Cycle=%0d | Time=%0t] SUM (Q0.16) = %.6f",
             tb_cycle_cnt, $time, sum_real);
  end
endtask

  // Stimulus
  initial begin
    // Init
    i_rst   = 1;
    i_start = 0;
    tb_probe_addr = 0;
    #20;
    i_rst = 0;

    // Start DUT
    #20;
    i_start = 1;
    #10;
    i_start = 0;

    // In input
    @(posedge dut.bramDone);
    print_matrixA();
    print_matrixB();

    // Đọc output softmax
    read_softmax_outputs();

    // Tính latency end-to-end
    $display("==============================================");
    $display("End-to-End Latency (cycles) = %0d", tb_cycle_cnt);
    $display("==============================================");

    $finish;
  end

  always_ff @(posedge i_clk) begin
    if (dut.wr_en_output) begin
      $display("[Cycle=%0d | Time=%0t] WRITE BRAM addr=%0d data=%0d",
               tb_cycle_cnt, $time,
               dut.wr_addr_output,
               dut.wr_data_output);
    end
  end
always_ff @(posedge i_clk) begin
  if (dut.softmax_valid) begin
    $display("SOFTMAX direct = %p", dut.o_softmax);
  end
end


endmodule
