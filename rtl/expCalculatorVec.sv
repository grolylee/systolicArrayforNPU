// expCalculatorVec.sv
module expCalculatorVec #(
  parameter int N           = 32,     // number of parallel exp calculators
  parameter int BIT_WIDTH   = 16,
  parameter int LUT_SIZE    = 64,
  parameter int ADDR_WIDTH  = 6,
  parameter int FRAC_BITS   = 12,
  parameter int MIN_FIXED   = -32768,
  parameter int H_FIXED     = 512
) (
  input  logic                              i_clk,
  input  logic                              i_rst,
  input  logic                              i_valid,          // common valid for all N inputs
  input  logic signed [BIT_WIDTH-1:0]       i_data   [N],     // array input: i_data[0] .. i_data[N-1]
  output logic signed [BIT_WIDTH-1:0]       o_exp    [N],     // array outputs
  output logic                              o_valid           // high when all o_exp[*] valid
);

  // per-instance wires
  logic signed [BIT_WIDTH-1:0] inst_o_exp [N];
  logic                        inst_o_valid [N];

  // Instantiate N copies of expCalculator
  genvar gi;
  generate
    for (gi = 0; gi < N; gi = gi + 1) begin : GEN_EXP
      // each instance gets the same parameter set (override here if needed)
      expCalculator #(
        .BIT_WIDTH  (BIT_WIDTH),
        .LUT_SIZE   (LUT_SIZE),
        .ADDR_WIDTH (ADDR_WIDTH),
        .FRAC_BITS  (FRAC_BITS),
        .MIN_FIXED  (MIN_FIXED),
        .H_FIXED    (H_FIXED)
      ) u_expcalc (
        .i_clk   (i_clk),
        .i_rst   (i_rst),
        .i_valid (i_valid),
        .i_data  (i_data[gi]),
        .o_exp   (inst_o_exp[gi]),
        .o_valid (inst_o_valid[gi])
      );
    end
  endgenerate

  // drive outputs from instance outputs
  // o_exp is simply the vector of inst_o_exp
  // assign using a loop to avoid tool-specific array-assign issues
  always_comb begin
    for (int i = 0; i < N; i++) begin
      o_exp[i] = inst_o_exp[i];
    end
  end

  // o_valid asserted when all instance o_valid are high (i.e., all results ready)
  // because every instance uses same i_valid and has same latency, these should align,
  // but we still compute reduction for robustness.
  logic all_valid;
  always_comb begin
    all_valid = 1'b1;
    for (int i = 0; i < N; i++) begin
      all_valid &= inst_o_valid[i];
    end
  end
  assign o_valid = all_valid;

endmodule
