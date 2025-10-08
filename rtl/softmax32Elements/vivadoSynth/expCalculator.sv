module expCalculator #(
  // latency 3 clk 
    parameter int BIT_WIDTH   = 16,
    parameter int LUT_SIZE    = 64,
    parameter int ADDR_WIDTH  = 6,   // log2(LUT_SIZE)
    parameter int FRAC_BITS   = 12,  // Q4.12 format
    parameter int MIN_FIXED   = -32768, // -8 * 4096
    parameter int H_FIXED     = 512     // 0.125 * 4096
) (
    input  logic                        i_clk,
    input  logic                        i_rst,
    input  logic                        i_valid,
    input  logic signed [BIT_WIDTH-1:0] i_data,
    output logic signed [BIT_WIDTH-1:0] o_exp,   // Q4.12
    output logic                        o_valid
);

  // pipelining registers
  logic signed [BIT_WIDTH-1:0] dataReg1, deltaFixed1;
  logic [ADDR_WIDTH-1:0]       index1;
  logic                        validReg1, validReg2, validReg3;

  // LUT array
  logic signed [BIT_WIDTH-1:0] expLut  [LUT_SIZE];
  logic signed [BIT_WIDTH-1:0] slopeLut[LUT_SIZE];


  initial begin
    expLut[0]  = 16'h0001;
    expLut[1]  = 16'h0002;
    expLut[2]  = 16'h0002;
    expLut[3]  = 16'h0002;
    expLut[4]  = 16'h0002;
    expLut[5]  = 16'h0003;
    expLut[6]  = 16'h0003;
    expLut[7]  = 16'h0003;
    expLut[8]  = 16'h0004;
    expLut[9]  = 16'h0004;
    expLut[10] = 16'h0005;
    expLut[11] = 16'h0005;
    expLut[12] = 16'h0006;
    expLut[13] = 16'h0007;
    expLut[14] = 16'h0008;
    expLut[15] = 16'h0009;
    expLut[16] = 16'h000a;
    expLut[17] = 16'h000c;
    expLut[18] = 16'h000d;
    expLut[19] = 16'h000f;
    expLut[20] = 16'h0011;
    expLut[21] = 16'h0013;
    expLut[22] = 16'h0015;
    expLut[23] = 16'h0018;
    expLut[24] = 16'h001c;
    expLut[25] = 16'h001f;
    expLut[26] = 16'h0023;
    expLut[27] = 16'h0028;
    expLut[28] = 16'h002e;
    expLut[29] = 16'h0034;
    expLut[30] = 16'h003a;
    expLut[31] = 16'h0042;
    expLut[32] = 16'h004b;
    expLut[33] = 16'h0055;
    expLut[34] = 16'h0060;
    expLut[35] = 16'h006d;
    expLut[36] = 16'h007c;
    expLut[37] = 16'h008c;
    expLut[38] = 16'h009f;
    expLut[39] = 16'h00b4;
    expLut[40] = 16'h00cc;
    expLut[41] = 16'h00e7;
    expLut[42] = 16'h0106;
    expLut[43] = 16'h0129;
    expLut[44] = 16'h0150;
    expLut[45] = 16'h017d;
    expLut[46] = 16'h01b0;
    expLut[47] = 16'h01e9;
    expLut[48] = 16'h022a;
    expLut[49] = 16'h0274;
    expLut[50] = 16'h02c8;
    expLut[51] = 16'h0327;
    expLut[52] = 16'h0392;
    expLut[53] = 16'h040c;
    expLut[54] = 16'h0496;
    expLut[55] = 16'h0532;
    expLut[56] = 16'h05e3;
    expLut[57] = 16'h06ab;
    expLut[58] = 16'h078f;
    expLut[59] = 16'h0890;
    expLut[60] = 16'h09b4;
    expLut[61] = 16'h0aff;
    expLut[62] = 16'h0c76;
    expLut[63] = 16'h0e1f;
  end

  // slopeLut values (from python generation)
  initial begin
    slopeLut[0]  = 16'h0001;
    slopeLut[1]  = 16'h0002;
    slopeLut[2]  = 16'h0002;
    slopeLut[3]  = 16'h0002;
    slopeLut[4]  = 16'h0002;
    slopeLut[5]  = 16'h0003;
    slopeLut[6]  = 16'h0003;
    slopeLut[7]  = 16'h0004;
    slopeLut[8]  = 16'h0004;
    slopeLut[9]  = 16'h0005;
    slopeLut[10] = 16'h0005;
    slopeLut[11] = 16'h0006;
    slopeLut[12] = 16'h0007;
    slopeLut[13] = 16'h0007;
    slopeLut[14] = 16'h0008;
    slopeLut[15] = 16'h000a;
    slopeLut[16] = 16'h000b;
    slopeLut[17] = 16'h000c;
    slopeLut[18] = 16'h000e;
    slopeLut[19] = 16'h0010;
    slopeLut[20] = 16'h0012;
    slopeLut[21] = 16'h0014;
    slopeLut[22] = 16'h0017;
    slopeLut[23] = 16'h001a;
    slopeLut[24] = 16'h001d;
    slopeLut[25] = 16'h0021;
    slopeLut[26] = 16'h0026;
    slopeLut[27] = 16'h002b;
    slopeLut[28] = 16'h0030;
    slopeLut[29] = 16'h0037;
    slopeLut[30] = 16'h003e;
    slopeLut[31] = 16'h0047;
    slopeLut[32] = 16'h0050;
    slopeLut[33] = 16'h005b;
    slopeLut[34] = 16'h0067;
    slopeLut[35] = 16'h0074;
    slopeLut[36] = 16'h0084;
    slopeLut[37] = 16'h0095;
    slopeLut[38] = 16'h00a9;
    slopeLut[39] = 16'h00c0;
    slopeLut[40] = 16'h00d9;
    slopeLut[41] = 16'h00f6;
    slopeLut[42] = 16'h0117;
    slopeLut[43] = 16'h013c;
    slopeLut[44] = 16'h0166;
    slopeLut[45] = 16'h0196;
    slopeLut[46] = 16'h01cc;
    slopeLut[47] = 16'h0209;
    slopeLut[48] = 16'h024e;
    slopeLut[49] = 16'h029d;
    slopeLut[50] = 16'h02f6;
    slopeLut[51] = 16'h035b;
    slopeLut[52] = 16'h03ce;
    slopeLut[53] = 16'h044f;
    slopeLut[54] = 16'h04e2;
    slopeLut[55] = 16'h0588;
    slopeLut[56] = 16'h0645;
    slopeLut[57] = 16'h071b;
    slopeLut[58] = 16'h080d;
    slopeLut[59] = 16'h091f;
    slopeLut[60] = 16'h0a56;
    slopeLut[61] = 16'h0bb7;
    slopeLut[62] = 16'h0d46;
    slopeLut[63] = 16'h0f0a;
  end


  // -------- Stage 1: tính index và delta --------
  logic signed [BIT_WIDTH+1:0] index_comb;
  logic signed [BIT_WIDTH+1:0] x0_comb;
  logic signed [BIT_WIDTH-1:0] delta_fixed_comb;

  always_comb begin
    index_comb       = ($signed(i_data + 32768) * LUT_SIZE) >>> 15;
    x0_comb          = $signed(MIN_FIXED + (index_comb[ADDR_WIDTH-1:0] * H_FIXED));
    delta_fixed_comb = i_data - x0_comb[BIT_WIDTH-1:0];
    if (delta_fixed_comb >= H_FIXED)      delta_fixed_comb = H_FIXED - 1;
    else if (delta_fixed_comb < -H_FIXED) delta_fixed_comb = -H_FIXED;
  end

  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      dataReg1    <= '0;
      index1      <= '0;
      deltaFixed1 <= '0;
      validReg1   <= 1'b0;
    end else begin
      validReg1   <= i_valid;
      if (i_valid) begin
        dataReg1    <= i_data;
        index1      <= index_comb[ADDR_WIDTH-1:0];
        deltaFixed1 <= delta_fixed_comb;
      end
    end
  end

  // -------- Stage 2: lookup LUT --------
  logic signed [BIT_WIDTH-1:0] expBaseReg, slopeReg, deltaFixed2;
  logic signed [BIT_WIDTH-1:0] dataReg2;

  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      expBaseReg  <= '0;
      slopeReg    <= '0;
      deltaFixed2 <= '0;
      dataReg2    <= '0;
      validReg2   <= 1'b0;
    end else begin
      validReg2   <= validReg1;
      if (validReg1) begin
        expBaseReg  <= expLut[index1];
        slopeReg    <= slopeLut[index1];
        deltaFixed2 <= deltaFixed1;
        dataReg2    <= dataReg1;
      end
    end
  end

  // -------- Stage 3: interpolation --------
  logic signed [2*BIT_WIDTH-1:0] product;

  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      o_exp     <= '0;
      validReg3 <= 1'b0;
      product   <= '0;
    end else begin
      validReg3 <= validReg2;
      if (validReg2) begin
        if (dataReg2 < MIN_FIXED) begin
          o_exp <= 16'sd0;
        end else if (dataReg2 == 0) begin
          o_exp <= 16'h1000; // 1.0 (Q4.12)
        end else begin
          product <= signed'(deltaFixed2) * signed'(slopeReg);
          o_exp   <= expBaseReg + signed'(product >>> FRAC_BITS);
          if (o_exp < 0)          o_exp <= 0;
          else if (o_exp > 16'sh7FFF) o_exp <= 16'sh7FFF;
        end
      end
    end
  end

  assign o_valid = validReg3;

endmodule
