// `timescale 1ns/1ps
// module tb_systolicArray8x8;

//   // Clock & reset
//   logic i_clk, i_arst;
//   logic i_validInput;
//   logic signed [7:0][7:0][7:0] i_a, i_b;
//   logic signed [7:0][7:0][31:0] o_c;
//   logic o_validResult;

//   // DUT
//   systolicArray8x8 dut (
//     .i_clk(i_clk),
//     .i_arst(i_arst),
//     .i_a(i_a),
//     .i_b(i_b),
//     .i_validInput(i_validInput),
//     .o_c(o_c),
//     .o_validResult(o_validResult)
//   );

//   // Clock gen
//   initial i_clk = 0;
//   always #5 i_clk = ~i_clk;

//   // Reference result
//   logic signed [7:0][7:0][31:0] ref_c;
//   int errors;   // declare trước

//   // === TASKS ===
//   task automatic gen_random_inputs();
//     for (int i = 0; i < 8; i++) begin
//       for (int j = 0; j < 8; j++) begin
//         i_a[i][j] = $urandom_range(0, 3); // nhỏ thôi để dễ check
//         i_b[i][j] = $urandom_range(0, 3);
//       end
//     end
//   endtask

//   task automatic compute_reference();
//     for (int i = 0; i < 8; i++) begin
//       for (int j = 0; j < 8; j++) begin
//         ref_c[i][j] = 0;
//         for (int k = 0; k < 8; k++) begin
//           ref_c[i][j] += i_a[i][k] * i_b[k][j];
//         end
//       end
//     end
//   endtask

//   task automatic print_matrix(string name, logic signed [7:0][7:0][31:0] mat);
//     $display("---- %s ----", name);
//     for (int i = 0; i < 8; i++) begin
//       for (int j = 0; j < 8; j++) begin
//         $write("%4d ", mat[i][j]);
//       end
//       $write("\n");
//     end
//   endtask

//   // === TEST ===
//   initial begin
//     i_arst = 1; i_validInput = 0; errors = 0;
//     #20 i_arst = 0;

//     gen_random_inputs();
//     compute_reference();

//     // apply input
//     @(posedge i_clk);
//     i_validInput = 1;
//     @(posedge i_clk);
//     i_validInput = 0;

//     // wait for result
//     wait(o_validResult);
//     @(posedge i_clk);

//     // print results
//     print_matrix("Matrix A", i_a);
//     print_matrix("Matrix B", i_b);
//     print_matrix("Reference C", ref_c);
//     print_matrix("DUT C", o_c);

//     // check mismatches
//     for (int i = 0; i < 8; i++) begin
//       for (int j = 0; j < 8; j++) begin
//         if (o_c[i][j] !== ref_c[i][j]) begin
//           $display("Mismatch at (%0d,%0d): ref=%0d, dut=%0d",
//                    i, j, ref_c[i][j], o_c[i][j]);
//           errors++;
//         end
//       end
//     end

//     if (errors == 0)
//       $display("==== TEST PASSED ====");
//     else
//       $display("==== TEST FAILED: %0d mismatches ====", errors);

//     $finish;
//   end

// endmodule


`timescale 1ns/1ps
module tb_systolicArray8x8;

  // Clock & reset
  logic i_clk, i_arst;
  logic i_validInput;
  logic signed [7:0][7:0][7:0] i_a, i_b;
  logic signed [7:0][7:0][31:0] o_c;
  logic o_validResult;

  // DUT
  systolicArray8x8 dut (
    .i_clk(i_clk),
    .i_arst(i_arst),
    .i_a(i_a),
    .i_b(i_b),
    .i_validInput(i_validInput),
    .o_c(o_c),
    .o_validResult(o_validResult)
  );

  // Clock gen
  initial i_clk = 0;
  always #5 i_clk = ~i_clk;

  // Reference result
  logic signed [7:0][7:0][31:0] ref_c;
  int errors;

  // === TASKS ===
  task automatic compute_reference();
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        ref_c[i][j] = 0;
        for (int k = 0; k < 8; k++) begin
          ref_c[i][j] += i_a[i][k] * i_b[k][j];
        end
      end
    end
  endtask

  task automatic print_matrix(string name, logic signed [7:0][7:0][31:0] mat);
    $display("---- %s ----", name);
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        $write("%4d ", mat[i][j]);
      end
      $write("\n");
    end
  endtask

  task automatic print_matrix_8bit(string name, logic signed [7:0][7:0][7:0] mat);
    $display("---- %s ----", name);
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        $write("%4d ", mat[i][j]);
      end
      $write("\n");
    end
  endtask

  // === TEST ===
  initial begin
    i_arst = 1; i_validInput = 0; errors = 0;
    #20 i_arst = 0;

    // Gán trực tiếp i_a và i_b từ log (a3 và b3 của Phase 1)
    i_a = '{
      '{1, 1, 1, 1, 1, 1, 0, 0},
      '{0, 0, 1, 1, 0, 1, 0, 1},
      '{0, 0, 1, 1, 0, 0, 0, 0},
      '{1, 0, 1, 1, 1, 0, 1, 0},
      '{0, 1, 1, 0, 0, 0, 0, 0},
      '{0, 1, 0, 0, 0, 1, 0, 0},
      '{1, 1, 1, 0, 1, 0, 0, 1},
      '{1, 0, 1, 0, 1, 1, 1, 1}
    };
    i_b = '{
      '{0, 1, 0, 1, 1, 1, 0, 0},
      '{0, 0, 1, 0, 0, 1, 1, 0},
      '{1, 1, 0, 0, 1, 0, 0, 0},
      '{1, 0, 0, 1, 1, 0, 0, 1},
      '{0, 1, 0, 1, 1, 1, 1, 0},
      '{0, 1, 0, 1, 1, 0, 1, 1},
      '{1, 0, 1, 0, 0, 0, 1, 1},
      '{0, 1, 1, 1, 0, 0, 1, 0}
    };

    compute_reference();

    // Apply input
    @(posedge i_clk);
    i_validInput = 1;
    @(posedge i_clk);
    i_validInput = 0;

    // Wait for result
    wait(o_validResult);
    @(posedge i_clk);

    // Print results
    print_matrix_8bit("Matrix A", i_a);
    print_matrix_8bit("Matrix B", i_b);
    print_matrix("Reference C", ref_c);
    print_matrix("DUT C", o_c);

    // Check mismatches
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        if (o_c[i][j] !== ref_c[i][j]) begin
          $display("Mismatch at (%0d,%0d): ref=%0d, dut=%0d",
                   i, j, ref_c[i][j], o_c[i][j]);
          errors++;
        end
      end
    end

    if (errors == 0)
      $display("==== TEST PASSED ====");
    else
      $display("==== TEST FAILED: %0d mismatches ====", errors);

    $finish;
  end

endmodule