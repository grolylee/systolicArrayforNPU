`timescale 1ns/1ps

module tb_testMult;

  // Clock & Reset
  logic i_clk;
  logic i_arst;
  logic i_validInput;
  logic signed [31:0][31:0][7:0]   i_a;
  logic signed [31:0][31:0][7:0]   i_b;
  logic signed [31:0][31:0][31:0]  o_c;
  logic o_validResult;

  // Clock gen
  initial i_clk = 0;
  always #5 i_clk = ~i_clk; // 100 MHz

  // DUT
  systolicArray32x32_new dut (
    .i_clk(i_clk),
    .i_arst(i_arst),
    .i_validInput(i_validInput),
    .i_a(i_a),
    .i_b(i_b),
    .o_c(o_c),
    .o_validResult(o_validResult)
  );

  // Reference model
  logic signed [31:0][31:0][31:0] ref_c;

  task matmul_ref(
    input  logic signed [31:0][31:0][7:0]  a,
    input  logic signed [31:0][31:0][7:0]  b,
    output logic signed [31:0][31:0][31:0] c
  );
    for (int i = 0; i < 32; i++) begin
      for (int j = 0; j < 32; j++) begin
        c[i][j] = 0;
        for (int k = 0; k < 32; k++) begin
          c[i][j] += a[i][k] * b[k][j];
        end
      end
    end
  endtask

  // Print matrix tasks
  task print_matrix_8bit(input string name, input logic signed [31:0][31:0][7:0] m);
    $display("---- %s ----", name);
    for (int i = 0; i < 32; i++) begin
      for (int j = 0; j < 32; j++) begin
        $write("%4d ", m[i][j]);
      end
      $write("\n");
    end
  endtask

  task print_matrix_32bit(input string name, input logic signed [31:0][31:0][31:0] m);
    $display("---- %s ----", name);
    for (int i = 0; i < 32; i++) begin
      for (int j = 0; j < 32; j++) begin
        $write("%8d ", m[i][j]);
      end
      $write("\n");
    end
  endtask

  // Test sequence
  initial begin
    int errors;  
    errors = 0;

    $display("===== 32x32 Systolic Array Test =====");
    // Reset
    i_arst = 1;
    i_validInput = 0;
    repeat(5) @(posedge i_clk);
    i_arst = 0;

    // Init A, B với giá trị ngẫu nhiên full 8-bit signed
    for (int i = 0; i < 32; i++) begin
      for (int j = 0; j < 32; j++) begin
        i_a[i][j] = $urandom_range(0, 10);
        i_b[i][j] = $urandom_range(0, 10);
      end
    end

    // Print input matrices
    print_matrix_8bit("Matrix A (random 8-bit)", i_a);
    print_matrix_8bit("Matrix B (random 8-bit)", i_b);

    // Expected result
    matmul_ref(i_a, i_b, ref_c);

    // Apply input
    @(posedge i_clk);
    i_validInput <= 1;
    @(posedge i_clk);
    i_validInput <= 0;

    // Wait for result
    wait(o_validResult == 1);
    @(posedge i_clk);

    // Print reference and DUT results
    print_matrix_32bit("Reference C (A*B)", ref_c);

    $display("---- DUT C (o_c) ----");
    for (int i = 0; i < 32; i++) begin
      for (int j = 0; j < 32; j++) begin
        if (o_c[i][j] !== ref_c[i][j]) begin
          $write("%8d(X) ", o_c[i][j]); // highlight mismatch
          errors++;
        end else begin
          $write("%8d    ", o_c[i][j]);
        end
      end
      $write("\n");
    end

    if (errors == 0)
      $display("===== TEST PASSED: All values match =====");
    else
      $display("===== TEST FAILED: %0d mismatches =====", errors);

    $finish;
  end

endmodule
