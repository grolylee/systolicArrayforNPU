module expCalculator #(
    parameter int BIT_WIDTH = 16,
    parameter int LUT_SIZE = 64,
    parameter int ADDR_WIDTH = 6,  // log2(LUT_SIZE)
    parameter int FRAC_BITS = 12,  // Q4.12 format
    parameter MIN_FIXED = -32768,  // Q4.12 minimum value -8 * 4096
    parameter int H_FIXED = 512    // 0.125 * 4096 (fixed-point)
) (
    input  logic                         i_clk,
    input  logic                         i_rst,
    input  logic                         i_valid,
    input  logic signed [BIT_WIDTH-1:0]  i_data,
    output logic signed [BIT_WIDTH-1:0]  o_exp,   // Q4.12
    output logic                         o_valid
);

  // pipelining registers
  logic signed [BIT_WIDTH-1:0] dataReg;
  logic signed [BIT_WIDTH-1:0] deltaFixed;
  logic [ADDR_WIDTH-1:0]       index;
  logic                        validReg1, validReg2, validReg3;

  // LUT arrays (simulated as a memory)
(* rom_style = "block" *)  logic signed [BIT_WIDTH-1:0] expLut  [LUT_SIZE];
(* rom_style = "block" *)  logic signed [BIT_WIDTH-1:0] slopeLut[LUT_SIZE];

  // Read LUT from .mem files
  initial begin
    $readmemh("expLut.mem", expLut);
    $readmemh("slopeLut.mem", slopeLut);
  end

  // Combinational for index & delta
  logic signed [BIT_WIDTH+1:0] index_comb;
  logic signed [BIT_WIDTH+1:0] x0_comb;
  logic signed [BIT_WIDTH-1:0] delta_fixed_comb;

  always_comb begin
    index_comb        = ($signed(i_data + 32768) * 64) >>> 15;
    x0_comb           = $signed(MIN_FIXED + (index_comb[ADDR_WIDTH-1:0] * H_FIXED));
    delta_fixed_comb  = i_data - x0_comb[BIT_WIDTH-1:0];
    // Clamp delta to [-H_FIXED, H_FIXED-1]
    if (delta_fixed_comb >= H_FIXED)      delta_fixed_comb = H_FIXED - 1;
    else if (delta_fixed_comb < -H_FIXED) delta_fixed_comb = -H_FIXED;
  end

  // -------- Stage 1 --------
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      index      <= '0;
      deltaFixed <= '0;
      dataReg    <= '0;
      validReg1  <= 1'b0;
    end else begin
      validReg1  <= i_valid;
      if (i_valid) begin
        dataReg    <= i_data;
        index      <= index_comb[ADDR_WIDTH-1:0];
        deltaFixed <= delta_fixed_comb;
      end
    end
  end

  // -------- Stage 2 --------
  logic signed [BIT_WIDTH-1:0] expBaseReg;
  logic signed [BIT_WIDTH-1:0] slopeReg;
  logic signed [BIT_WIDTH-1:0] deltaFixedReg;

  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      expBaseReg     <= '0;
      slopeReg       <= '0;
      deltaFixedReg  <= '0;
      validReg2      <= 1'b0;
    end else begin
      validReg2      <= validReg1;
      if (validReg1) begin
        expBaseReg     <= expLut[index];
        slopeReg       <= slopeLut[index];
        deltaFixedReg  <= deltaFixed;
      end
    end
  end

  // -------- Stage 3 --------
    (* use_dsp = "yes" *) logic signed [2*BIT_WIDTH-1:0] product;
  logic signed [BIT_WIDTH-1:0]   o_exp_comb;

  // Combinational logic for product and o_exp
  always_comb begin
    logic signed [2*BIT_WIDTH-1:0] temp_product;
    logic signed [BIT_WIDTH-1:0]   temp_o_exp;

    if (dataReg < MIN_FIXED) begin
      temp_o_exp = 16'sd0;
      temp_product = '0;
    end else if (dataReg == 0) begin
      temp_o_exp = 16'h1000; // 1.0 (Q4.12)
      temp_product = '0;
    end else begin
      temp_product = $signed(deltaFixedReg) * $signed(slopeReg);
      // Clamp product
      if (temp_product > (2 ** (BIT_WIDTH + FRAC_BITS) - 1))
        temp_product = (2 ** (BIT_WIDTH + FRAC_BITS) - 1);
      else if (temp_product < -(2 ** (BIT_WIDTH + FRAC_BITS)))
        temp_product = -(2 ** (BIT_WIDTH + FRAC_BITS));
      // Calculate o_exp
      temp_o_exp = expBaseReg + $signed(temp_product >>> FRAC_BITS);
      // Clamp o_exp
      if (temp_o_exp < 0)
        temp_o_exp = 0;
      else if (temp_o_exp > 16'sh7FFF)
        temp_o_exp = 16'sh7FFF;
    end
    o_exp_comb = temp_o_exp;
  end

  // Sequential logic to update registers
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      o_exp     <= '0;
      validReg3 <= '0;
      product   <= '0;
    end else begin
      validReg3 <= validReg2;
      if (validReg2) begin
        o_exp <= o_exp_comb;
      end
    end
  end

  assign o_valid = validReg3;

endmodule