`timescale 1ns / 1ps

module tb_topDesignSA;

    logic i_clk;
    logic i_rst;
    logic i_start;
    logic signed [31:0][31:0][31:0] o_c ;
    logic signed [31:0] o_c_result [0:1023];
    logic o_validResult;
  
    int num_pass = 0;
    int num_fail = 0;
    
    // DUT
    topDesignSA dut (
      .i_clk(i_clk),
      .i_rst(i_rst),
      .i_start(i_start),
      .o_validResult(o_validResult)
    );
  
    // Clock generation
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;
  
    // Task in ma trận A
    task print_matrixA;
      $display("Input Matrix A:");
      for (int i = 0; i < 32; i++) begin
        for (int j = 0; j < 32; j++) begin
          $write("%0d ", dut.u_bram_fsm.o_matrixA[i][j]);
        end
        $write("\n");
      end
    endtask
  
    // Task in ma trận B
    task print_matrixB;
      $display("Input Matrix B:");
      for (int i = 0; i < 32; i++) begin
        for (int j = 0; j < 32; j++) begin
          $write("%0d ", dut.u_bram_fsm.o_matrixB[i][j]);
        end
        $write("\n");
      end
    endtask
  always @(posedge i_clk) begin
    $display("[%0t] fsm_bram_reader_dual: state=%0d addr_cnt=%0d start=%b done=%b",
             $time,
             dut.u_bram_fsm.u_fsm.state,
             dut.u_bram_fsm.u_fsm.addr_cnt,
             dut.u_bram_fsm.u_fsm.start,
             dut.u_bram_fsm.u_fsm.done);
end

    // Task in 10 phần tử đầu ra
    task print_output_result;
      $display("Output Result:");
//      for (int i = 0; i < 10; i++) begin
//        $write("%0d ", o_c_result[i]);
//        $write("\n");
//      e
      for (int i = 0; i < 32; i++) begin
        for (int j = 0; j < 32; j++) begin
          $write("%0d ", dut.o_cScaleClip[i][j]);
        end
        $write("\n");
      end
    endtask
  

    task write_output_coe;
      integer file;
      file = $fopen("/home/hieuld/Documents/do-an2_i3/vit_npu/rtl/vit_final/output.coe", "w");
      if (file) begin
        $fwrite(file, "memory_initialization_radix=10;\n");
        $fwrite(file, "memory_initialization_vector=\n");
        for (int i = 0; i < 32; i++) begin
          for (int j = 0; j < 32; j++) begin
            $fwrite(file, "%d", dut.o_cScaleClip[i][j]);
            if (!(i == 31 && j == 31)) $fwrite(file, ", ");
            if (j == 31) $fwrite(file, "\n");
          end
        end
        $fwrite(file, ";\n");
        $fclose(file);
        $display("[STATUS] File output.coe success created!");
        num_pass++;
      end else begin
        $display("[FAIL] Not create file output.coe!");
        num_fail++;
      end
    endtask
  

    task check_matrix_input;
      bit pass = 1;
      for (int i = 0; i < 32; i++) begin
        for (int j = 0; j < 32; j++) begin
          if (dut.u_bram_fsm.o_matrixA[i][j] === 'x || dut.u_bram_fsm.o_matrixB[i][j] === 'x) begin
            $display("[FAIL] Detected X at A[%0d][%0d] hoặc B[%0d][%0d]", i, j, i, j);
            pass = 0;
          end
        end
      end
      if (pass) begin
        $display("[PASS] Input A and B valid (not detect X).");
        num_pass++;
      end else begin
        $display("[FAIL] Detect undefined value in input.");
        num_fail++;
      end
    endtask
  
 
//    task check_matrix_multiplication_result;
//    bit pass = 1;
//    int k = 0;
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        if (dut.o_rd_data[k] !== dut.o_c[i][j]) begin
//          $display("[FAIL] C[%0d][%0d]: expected = %0d, got = %0d", i, j, dut.o_rd_data[k], dut.o_c[i][j]);
//          pass = 0;
//        end
//        k++;
//  //      if (k >= 10) break;  // Kiểm tra giới hạn 10 phần tử đầu
//      end
//  //    if (k >= 10) break;
//    end
  
//    if (pass) begin
//      $display("[PASS] Accurate results.");
//      num_pass++;
//    end else begin
//      $display("[FAIL] Error in matrix multiplication result.");
//      num_fail++;
//    end
//  endtask
  
  
    // Stimulus chính
    initial begin
      i_rst = 1;
      i_start = 0;
      #20;
      i_rst = 0;
      #10;
      i_start = 1;
      #10;
      i_start = 0;
  
      wait (o_validResult); 
  
      print_matrixA();
      print_matrixB();
      print_output_result();
  
      check_matrix_input();
//      check_matrix_multiplication_result();
      write_output_coe();
  
      $display("\n========== VERIFICATION ==========");
      $display("TEST PASS: %0d", num_pass);
      $display("TEST FAIL: %0d", num_fail);
      if (num_fail == 0)
        $display("[FINAL RESULT] ALL TEST PASS!");
      else
        $display("[FINAL RESULT] ❌ DETECTED FAIL!");
  
      $finish();
    end
  
  endmodule




//`timescale 1ns / 1ps

//module tb_topDesignSA;

//  logic i_clk;
//  logic i_rst;
//  logic i_start;
//  logic signed [15:0] o_c_result [0:1023];
//  logic o_validResult;
//  logic [15:0] bram_data_out;

//  int num_pass = 0;
//  int num_fail = 0;

//  // DUT
//  topDesignSA dut (
//    .i_clk(i_clk),
//    .i_rst(i_rst),
//    .i_start(i_start),
//    .o_c_result(o_c_result),
//    .o_validResult(o_validResult)
//  );

//  // Gán tín hiệu đọc từ BRAM (port B)
//  assign bram_data_out = dut.u_result_bram.doutb;

//  // Clock generation
//  initial i_clk = 0;
//  always #5 i_clk = ~i_clk;

//  // Task in ma trận A
//  task print_matrixA;
//    $display("Input Matrix A:");
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        $write("%0d ", dut.u_bram_fsm.o_matrixA[i][j]);
//      end
//      $write("\n");
//    end
//  endtask

//  // Task in ma trận B
//  task print_matrixB;
//    $display("Input Matrix B:");
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        $write("%0d ", dut.u_bram_fsm.o_matrixB[i][j]);
//      end
//      $write("\n");
//    end
//  endtask

//  // Task in ma trận kết quả
//  task print_output_result;
//    $display("Output Result (32x32):");
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        $write("%0d ", dut.o_c[i][j]);
//      end
//      $write("\n");
//    end
//  endtask

//  // Task ghi file output.coe từ BRAM
//  task write_bram_output_coe;
//    integer file;
//    file = $fopen("bram_output.coe", "w");
//    if (file) begin
//      $fwrite(file, "memory_initialization_radix=10;\n");
//      $fwrite(file, "memory_initialization_vector=\n");
//      for (int i = 0; i < 1024; i++) begin
//        @(posedge i_clk);
//        $fwrite(file, "%0d", bram_data_out);
//        if (i != 1023) $fwrite(file, ", ");
//        else $fwrite(file, ";\n");
//      end
//      $fclose(file);
//      $display("[STATUS] File bram_output.coe success created!");
//      num_pass++;
//    end else begin
//      $display("[FAIL] Cannot open file bram_output.coe!");
//      num_fail++;
//    end
//  endtask

//  // Task in dữ liệu từ BRAM
//  task print_bram_output_direct;
//    $display("BRAM Output (read from port B):");
//    for (int i = 0; i < 1024; i++) begin
//      @(posedge i_clk);
//      $display("BRAM[%0d] = %0d", i, bram_data_out);
//    end
//  endtask

//  // Task kiểm tra input A & B không bị X
//  task check_matrix_input;
//    bit pass = 1;
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        if (dut.u_bram_fsm.o_matrixA[i][j] === 'x || dut.u_bram_fsm.o_matrixB[i][j] === 'x) begin
//          $display("[FAIL] Detected X at A[%0d][%0d] hoặc B[%0d][%0d]", i, j, i, j);
//          pass = 0;
//        end
//      end
//    end
//    if (pass) begin
//      $display("[PASS] Input A and B valid (not detect X).");
//      num_pass++;
//    end else begin
//      $display("[FAIL] Detect undefined value in input.");
//      num_fail++;
//    end
//  endtask

//  // Task kiểm tra dữ liệu BRAM có giống o_c_result không
//  task check_bram_vs_result;
//    bit pass = 1;
//    for (int i = 0; i < 1024; i++) begin
//      @(posedge i_clk);
//      if (bram_data_out !== o_c_result[i]) begin
//        $display("[FAIL] BRAM[%0d]: expected = %0d, got = %0d", i, o_c_result[i], bram_data_out);
//        pass = 0;
//      end
//    end
//    if (pass) begin
//      $display("[PASS] BRAM matches o_c_result.");
//      num_pass++;
//    end else begin
//      $display("[FAIL] BRAM data mismatch.");
//      num_fail++;
//    end
//  endtask

//  // Main stimulus
//  initial begin
//    i_rst = 1;
//    i_start = 0;
//    #20;
//    i_rst = 0;
//    #10;
//    i_start = 1;
//    #10;
//    i_start = 0;

//    wait (o_validResult);

//    // Đợi FSM ghi & đọc BRAM xong (thường vài ngàn ns là đủ)
//    #20000;

//    print_matrixA();
//    print_matrixB();
//    print_output_result();

//    print_bram_output_direct();         // ✅ In dữ liệu từ BRAM
//    check_bram_vs_result();             // ✅ So sánh với o_c_result
//    write_bram_output_coe();            // ✅ Ghi ra file .coe
//    check_matrix_input();               // ✅ Kiểm tra X

//    // Summary
//    $display("\n========== VERIFICATION ==========");
//    $display("TEST PASS: %0d", num_pass);
//    $display("TEST FAIL: %0d", num_fail);
//    if (num_fail == 0)
//      $display("[FINAL RESULT] ✅ ALL TEST PASS!");
//    else
//      $display("[FINAL RESULT] ❌ DETECTED FAIL!");

//    $finish();
//  end

//endmodule








//  `timescale 1ns / 1ps

// module tb_topDesignSA;

//  logic i_clk;
//  logic i_rst;
//  logic i_start;
//  logic signed [31:0][31:0][31:0] o_c;
//  logic signed [31:0] o_c_result;
//  logic o_validResult;

//  int num_pass = 0;
//  int num_fail = 0;

//  // DUT
//  topDesignSA dut (
//    .i_clk(i_clk),
//    .i_rst(i_rst),
//    .i_start(i_start),
//    .o_validResult(o_validResult)
//  );

//  // Clock generation
//  initial i_clk = 0;
//  always #5 i_clk = ~i_clk;

//  // Task in ma trận A
//  task print_matrixA;
//    $display("Input Matrix A:");
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        $write("%0d ", dut.u_bram_fsm.o_matrixA[i][j]);
//      end
//      $write("\n");
//    end
//  endtask

//  // Task in ma trận B
//  task print_matrixB;
//    $display("Input Matrix B:");
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        $write("%0d ", dut.u_bram_fsm.o_matrixB[i][j]);
//      end
//      $write("\n");
//    end
//  endtask

//  // Task in kết quả đầu ra từ DUT
//  task print_output_result;
//    $display("Output Result (dut.o_c):");
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        $write("%0d ", dut.o_c[i][j]);
//      end
//      $write("\n");
//    end
//  endtask

//  // Task ghi file COE
//  task write_output_coe;
//    integer file;
//    file = $fopen("output.coe", "w");
//    if (file) begin
//      $fwrite(file, "memory_initialization_radix=10;\n");
//      $fwrite(file, "memory_initialization_vector=\n");
//      for (int i = 0; i < 32; i++) begin
//        for (int j = 0; j < 32; j++) begin
//          $fwrite(file, "%d", dut.o_c[i][j]);
//          if (!(i == 31 && j == 31)) $fwrite(file, ", ");
//          if (j == 31) $fwrite(file, "\n");
//        end
//      end
//      $fwrite(file, ";\n");
//      $fclose(file);
//      $display("[STATUS] File output.coe success created!");
//    end else begin
//      $display("[FAIL] Cannot create file output.coe!");
//      num_fail++;
//    end
//  endtask

//  // Task kiểm tra dữ liệu input
//  task check_matrix_input;
//    bit pass = 1;
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
//        if (dut.u_bram_fsm.o_matrixA[i][j] === 'x || dut.u_bram_fsm.o_matrixB[i][j] === 'x) begin
//          $display("[FAIL] X detected at A[%0d][%0d] or B[%0d][%0d]", i, j, i, j);
//          pass = 0;
//        end
//      end
//    end
//    if (pass) begin
//      $display("[PASS] Input A and B are valid.");
//      num_pass++;
//    end else begin
//      $display("[FAIL] Invalid input values.");
//      num_fail++;
//    end
//  endtask

//  // Task kiểm tra kết quả nhân ma trận
//  task check_matrix_multiplication_result;
//    bit pass = 1;
//    int k = 0;
//    for (int i = 0; i < 32; i++) begin
//      for (int j = 0; j < 32; j++) begin
// //        if (o_c_result[k] !== dut.o_c[i][j]) begin
// //          $display("[FAIL] C[%0d][%0d]: expected = %0d, got = %0d", i, j, dut.o_c[i][j], o_c_result[k]);
// //          pass = 0;
// //        end

//        if (dut.u_flatten.o_data[k] !== dut.o_c[i][j]) begin
//          $display("[FAIL] C[%0d][%0d]: expected = %0d, got = %0d", i, j, dut.o_c[i][j], dut.u_flatten.o_data[k]);
//          pass = 0;
//        end
//        k++;
//      end
//    end

//    if (pass) begin
//      $display("[PASS] Matrix multiplication result is correct.");
//      num_pass++;
//    end else begin
//      $display("[FAIL] Incorrect result in matrix multiplication.");
//      num_fail++;
//    end
//  endtask

//  // Stimulus chính
//  initial begin
//    i_rst = 1;
//    i_start = 0;
//    repeat(2) @(posedge i_clk);
//    i_rst = 0;
//    repeat(2) @(posedge i_clk);
//    i_start = 1;
//    @(posedge i_clk);
//    i_start = 0;

//    wait(o_validResult);
//    @(posedge i_clk); // Đợi thêm để đảm bảo dữ liệu ổn định

//    print_matrixA();
//    print_matrixB();
//    print_output_result();

//    check_matrix_input();
//    check_matrix_multiplication_result();
//    write_output_coe();

//    $display("\n========== VERIFICATION REPORT ==========");
//    $display("TOTAL PASS: %0d", num_pass);
//    $display("TOTAL FAIL: %0d", num_fail);
//    if (num_fail == 0)
//      $display("[FINAL RESULT] ✅ ALL TESTS PASSED!");
//    else
//      $display("[FINAL RESULT] ❌ TESTS FAILED!");

//    $finish();
//  end

// endmodule
