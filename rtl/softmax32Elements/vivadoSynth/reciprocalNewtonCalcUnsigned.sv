module reciprocalNewtonCalcUnsigned #(
    parameter int IN_WIDTH   = 32,   // Q6.26 input
    parameter int BIT_WIDTH  = 16,   // Q0.16 output
    parameter int LUT_SIZE   = 256,
    parameter int ITERATIONS = 4
) (
    input  logic                 i_clk,
    input  logic                 i_rst,
    input  logic                 i_valid,
    input  logic [IN_WIDTH-1:0]  i_sum,         // Q6.26, unsigned
    output logic [BIT_WIDTH-1:0] o_reciprocal,  // Q0.16, unsigned
    output logic                 o_valid
);
    // ---- Range cho softmax sum: 1.0 .. 32.0 trong Q6.26 ----
    // 1.0  * 2^26 = 2^26 = 67_108_864
    // 32.0 * 2^26 = 2^31 = 2_147_483_648
    localparam logic [31:0] MIN_SUM = 32'd67108864;     // 1.0
    localparam logic [31:0] MAX_SUM = 32'd2147483648;   // 32.0

    // ---- LUT cho x0 ~ 1/a ----
    // Khuyến nghị: lut[0] ~ 1/1.0, lut[255] ~ 1/32.0 (đều ở Q0.16)
    logic [BIT_WIDTH-1:0] lut[LUT_SIZE];
    initial $readmemh("lut1to32_reciprocal.mem", lut);

    // ---- Pipeline ----
    logic [7:0]            lut_index;
    logic [BIT_WIDTH-1:0]  xReg    [ITERATIONS:0];   // x0..xN (Q0.16)
    logic [IN_WIDTH-1:0]   aReg    [ITERATIONS:0];   // a giữ nguyên (Q6.26)
    logic                  vReg    [ITERATIONS:0];

    // Map [1.0..32.0] -> [0..255] gần tuyến tính bằng dịch phải 23
    // (2^31 - 2^26) >> 23 ≈ 248 -> phủ gần hết 256 ô LUT
    always_comb begin
        if (i_sum <= MIN_SUM)       lut_index = 8'd0;
        else if (i_sum >= MAX_SUM)  lut_index = 8'd255;
        else                        lut_index = (i_sum - MIN_SUM) >> 23;
    end

    // Stage 0: lấy x0 từ LUT
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            xReg[0]   <= '0;
            aReg[0]   <= '0;
            vReg[0]   <= 1'b0;
        end else begin
            xReg[0]   <= i_valid ? lut[lut_index] : '0; // Q0.16
            aReg[0]   <= i_sum;                          // Q6.26
            vReg[0]   <= i_valid;
        end
    end

    // Newton-Raphson: x_{k+1} = x_k * (2 - a*x_k)
    // a: Q6.26, x: Q0.16
    // a*x: Q6.26 * Q0.16 = Q6.42  (dùng 64-bit để an toàn)
    // (2 - a*x): vẫn Q6.42
    // Chuyển Q6.42 -> Q2.16 bằng RIGHT-SHIFT 26 (có làm tròn)
    // rồi x * corr: Q0.16 * Q2.16 = Q2.32 -> Q0.16 (>>16, có làm tròn)
    function automatic [BIT_WIDTH-1:0] nr_step_q6_26_q0_16 (
        input [BIT_WIDTH-1:0] x_in,     // Q0.16
        input [IN_WIDTH-1:0]  a_in      // Q6.26
    );
        // wide sản phẩm và trung gian
        logic [63:0] ax_q6_42;      // a*x
        logic [63:0] two_q6_42;     // 2.0 trong Q6.42
        logic [63:0] corr_q6_42;    // (2 - a*x)
        logic [17:0] corr_q2_16;    // Q2.16 (18-bit: 2 int + 16 frac)
        logic [33:0] xcorr_q2_32;   // Q2.32

        begin
            ax_q6_42   = a_in * x_in;            // Q6.42
            two_q6_42  = 64'd2 << 42;            // 2.0 (Q6.42)
            corr_q6_42 = two_q6_42 - ax_q6_42;   // Q6.42

            // Q6.42 -> Q2.16 : shift phải 26, làm tròn nửa LSB
            // (corr_q6_42 + 0.5*2^26) >> 26
            corr_q2_16 = (corr_q6_42 + (64'd1 << 25)) >> 26;  // 18-bit đủ chứa [0..~3.999]

            // x * corr: Q0.16 * Q2.16 = Q2.32
            xcorr_q2_32 = x_in * corr_q2_16;

            // Q2.32 -> Q0.16 (>>16, làm tròn)
            nr_step_q6_26_q0_16 = xcorr_q2_32[31:16] + xcorr_q2_32[15];
        end
    endfunction

    genvar k;
    generate
        for (k = 1; k <= ITERATIONS; k++) begin : gen_nr
            always_ff @(posedge i_clk or posedge i_rst) begin
                if (i_rst) begin
                    xReg[k] <= '0;
                    aReg[k] <= '0;
                    vReg[k] <= 1'b0;
                end else if (vReg[k-1]) begin
                    xReg[k] <= nr_step_q6_26_q0_16(xReg[k-1], aReg[k-1]);
                    aReg[k] <= aReg[k-1];
                    vReg[k] <= 1'b1;
                end else begin
                    xReg[k] <= '0;
                    aReg[k] <= aReg[k-1];
                    vReg[k] <= 1'b0;
                end
            end
        end
    endgenerate

    // Output
assign    o_reciprocal = xReg[ITERATIONS]; // Q0.16
assign    o_valid      = vReg[ITERATIONS];
endmodule
