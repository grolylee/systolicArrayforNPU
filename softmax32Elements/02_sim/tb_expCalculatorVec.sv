



`timescale 1ns/1ps

module tb_expCalculatorVec;

  localparam int N          = 4;
  localparam int BIT_WIDTH  = 16;

  // DUT signals
  logic                        clk, rst;
  logic                        i_valid;
  logic signed [BIT_WIDTH-1:0] i_data [N];
  logic signed [BIT_WIDTH-1:0] o_exp  [N];
  logic                        o_valid;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk; // 100MHz

  // DUT instantiation
  expCalculatorVec #(
    .N(N),
    .BIT_WIDTH(BIT_WIDTH)
  ) dut (
    .i_clk(clk),
    .i_rst(rst),
    .i_valid(i_valid),
    .i_data(i_data),
    .o_exp(o_exp),
    .o_valid(o_valid)
  );

  // ==============================
  // Test vectors (input & expected)
  // ==============================
  // input values (Q4.12)
  logic signed [BIT_WIDTH-1:0] stim_vec [2][N] = '{
    '{-16'sd3872, -16'sd1379,  16'sd0,    -16'sd722},
    '{-16'sd4321,  16'sd0,    -16'sd5080, -16'sd3567}
  };

  // expected outputs (Q4.12 fixed-point), tính sẵn ở ngoài bằng Python/Matlab
  // ví dụ: expected_exp[0] = int(round(exp(real(i_data[0])/4096.0)*4096))
  logic signed [BIT_WIDTH-1:0] expected_exp [2][N] = '{
    '{16'sd1591, 16'sd2925, 16'sd4096, 16'sd3434},
    '{16'sd1426, 16'sd4096, 16'sd1185, 16'sd1715}
  };

  // Stimulus
  initial begin
    rst = 1;
    i_valid = 0;
    for (int i=0; i<N; i++) i_data[i] = 0;
    #20;
    rst = 0;

    // apply two vectors
    for (int v = 0; v < 2; v++) begin
      @(negedge clk);
      i_valid = 1;
      for (int i=0; i<N; i++) i_data[i] = stim_vec[v][i];
    end

    @(negedge clk);
    i_valid = 0;

    repeat(15) @(posedge clk);
    $finish;
  end

  // Monitor outputs + compare
  int vec_idx = 0;
  always_ff @(posedge clk) begin
    if (o_valid) begin
      $display("[%0t] DUT Outputs vs Expected:", $time);
      for (int k=0; k<N; k++) begin
        $display("  ch%0d: DUT=%0d  EXP=%0d", k, o_exp[k], expected_exp[vec_idx][k]);
        if (o_exp[k] !== expected_exp[vec_idx][k]) begin
          $error("Mismatch at vec%0d ch%0d: DUT=%0d expected=%0d",
                  vec_idx, k, o_exp[k], expected_exp[vec_idx][k]);
        end
      end
      vec_idx++;
    end
  end

endmodule



