`timescale 1ns/1ps

module tb_systolicArray4x4;

  // Parameters
  localparam int N = 4;

  // Signals
  logic i_clk;
  logic i_arst;
  logic i_validInput;
  logic signed [N-1:0][N-1:0][7:0]  i_a;
  logic signed [N-1:0][N-1:0][7:0]  i_b;
  logic signed [N-1:0][N-1:0][31:0] o_c;
  logic o_validResult;

  // Clock generation: 100 MHz
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
  end

  // DUT
  systolicArray4x4 #(.N(N)) dut (
    .i_clk        (i_clk),
    .i_arst       (i_arst),
    .i_a          (i_a),
    .i_b          (i_b),
    .i_validInput (i_validInput),
    .o_c          (o_c),
    .o_validResult(o_validResult)
  );

  // Task: init matrices with simple pattern
  task init_matrices;
    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        i_a[i][j] = i + j;          // ví dụ A(i,j) = i+j
        i_b[i][j] = (i==j) ? 1 : 0; // B = ma trận đơn vị
      end
    end
  endtask

  // Function: check result
  function automatic void check_result(
    input logic signed [N-1:0][N-1:0][7:0] a,
    input logic signed [N-1:0][N-1:0][7:0] b,
    input logic signed [N-1:0][N-1:0][31:0] c
  );
    int sum;
    for (int i=0; i<N; i++) begin
      for (int j=0; j<N; j++) begin
        sum = 0;
        for (int k=0; k<N; k++) begin
          sum += a[i][k] * b[k][j];
        end
        if (c[i][j] !== sum) begin
          $error("Mismatch at (%0d,%0d): expected %0d, got %0d",
                 i, j, sum, c[i][j]);
        end else begin
          $display("PASS (%0d,%0d): %0d", i, j, c[i][j]);
        end
      end
    end
  endfunction

  // Simulation
  initial begin
    // Dump waveform
    $dumpfile("tb_systolicArray4x4.vcd");
    $dumpvars(0, tb_systolicArray4x4);

    // Reset
    i_arst = 1;
    i_validInput = 0;
    init_matrices(); // load data trước khi nhả reset
    #20;
    i_arst = 0;

    // Gửi input
    @(negedge i_clk);
    i_validInput = 1;
    @(negedge i_clk);
    i_validInput = 0;

    // Chờ kết quả
    wait(o_validResult == 1);
    $display("===== 4x4 Multiplication Result =====");
    check_result(i_a, i_b, o_c);

    #50;
    $finish;
  end

endmodule
