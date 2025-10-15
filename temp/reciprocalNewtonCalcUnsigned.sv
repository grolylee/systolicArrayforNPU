// // module reciprocalNewtonCalcUnsigned #(
// //     parameter int IN_WIDTH   = 32,   // Q6.26 input
// //     parameter int BIT_WIDTH  = 16,   // Q0.16 output
// //     parameter int LUT_SIZE   = 256,
// //     parameter int ITERATIONS = 2
// // ) (
// //     input  logic                 i_clk,
// //     input  logic                 i_rst,
// //     input  logic                 i_valid,
// //     input  logic [IN_WIDTH-1:0]  i_sum,         // Q6.26, unsigned
// //     output logic [BIT_WIDTH-1:0] o_reciprocal,  // Q0.16, unsigned
// //     output logic                 o_valid
// // );
// //     // ---- Range cho softmax sum: 1.0 .. 32.0 trong Q6.26 ----
// //     // 1.0  * 2^26 = 2^26 = 67_108_864
// //     // 32.0 * 2^26 = 2^31 = 2_147_483_648
// //     localparam logic [31:0] MIN_SUM = 32'd67108864;     // 1.0
// //     localparam logic [31:0] MAX_SUM = 32'd2147483648;   // 32.0

// //     // ---- LUT cho x0 ~ 1/a ----
// //     // Khuyến nghị: lut[0] ~ 1/1.0, lut[255] ~ 1/32.0 (đều ở Q0.16)
// //     logic [BIT_WIDTH-1:0] lut[LUT_SIZE];
// //     initial $readmemh("lut1to32_reciprocal.mem", lut);

// //     // ---- Pipeline ----
// //     logic [7:0]            lut_index;
// //     logic [BIT_WIDTH-1:0]  xReg    [ITERATIONS:0];   // x0..xN (Q0.16)
// //     logic [IN_WIDTH-1:0]   aReg    [ITERATIONS:0];   // a giữ nguyên (Q6.26)
// //     logic                  vReg    [ITERATIONS:0];

// //     // Map [1.0..32.0] -> [0..255] gần tuyến tính bằng dịch phải 23
// //     // (2^31 - 2^26) >> 23 ≈ 248 -> phủ gần hết 256 ô LUT
// //     always_comb begin
// //         if (i_sum <= MIN_SUM)       lut_index = 8'd0;
// //         else if (i_sum >= MAX_SUM)  lut_index = 8'd255;
// //         else                        lut_index = (i_sum - MIN_SUM) >> 23;
// //     end

// //     // Stage 0: lấy x0 từ LUT
// //     always_ff @(posedge i_clk or posedge i_rst) begin
// //         if (i_rst) begin
// //             xReg[0]   <= '0;
// //             aReg[0]   <= '0;
// //             vReg[0]   <= 1'b0;
// //         end else begin
// //             xReg[0]   <= i_valid ? lut[lut_index] : '0; // Q0.16
// //             aReg[0]   <= i_sum;                          // Q6.26
// //             vReg[0]   <= i_valid;
// //         end
// //     end

// //     // Newton-Raphson: x_{k+1} = x_k * (2 - a*x_k)
// //     // a: Q6.26, x: Q0.16
// //     // a*x: Q6.26 * Q0.16 = Q6.42  (dùng 64-bit để an toàn)
// //     // (2 - a*x): vẫn Q6.42
// //     // Chuyển Q6.42 -> Q2.16 bằng RIGHT-SHIFT 26 (có làm tròn)
// //     // rồi x * corr: Q0.16 * Q2.16 = Q2.32 -> Q0.16 (>>16, có làm tròn)
// //     function automatic [BIT_WIDTH-1:0] nr_step_q6_26_q0_16 (
// //         input [BIT_WIDTH-1:0] x_in,     // Q0.16
// //         input [IN_WIDTH-1:0]  a_in      // Q6.26
// //     );
// //         // wide sản phẩm và trung gian
// //         logic [63:0] ax_q6_42;      // a*x
// //         logic [63:0] two_q6_42;     // 2.0 trong Q6.42
// //         logic [63:0] corr_q6_42;    // (2 - a*x)
// //         logic [17:0] corr_q2_16;    // Q2.16 (18-bit: 2 int + 16 frac)
// //         logic [33:0] xcorr_q2_32;   // Q2.32

// //         begin
// //             ax_q6_42   = a_in * x_in;            // Q6.42
// //             two_q6_42  = 64'd2 << 42;            // 2.0 (Q6.42)
// //             corr_q6_42 = two_q6_42 - ax_q6_42;   // Q6.42

// //             // Q6.42 -> Q2.16 : shift phải 26, làm tròn nửa LSB
// //             // (corr_q6_42 + 0.5*2^26) >> 26
// //             corr_q2_16 = (corr_q6_42 + (64'd1 << 25)) >> 26;  // 18-bit đủ chứa [0..~3.999]

// //             // x * corr: Q0.16 * Q2.16 = Q2.32
// //             xcorr_q2_32 = x_in * corr_q2_16;

// //             // Q2.32 -> Q0.16 (>>16, làm tròn)
// //             nr_step_q6_26_q0_16 = xcorr_q2_32[31:16] + xcorr_q2_32[15];
// //         end
// //     endfunction

// //     genvar k;
// //     generate
// //         for (k = 1; k <= ITERATIONS; k++) begin : gen_nr
// //             always_ff @(posedge i_clk or posedge i_rst) begin
// //                 if (i_rst) begin
// //                     xReg[k] <= '0;
// //                     aReg[k] <= '0;
// //                     vReg[k] <= 1'b0;
// //                 end else if (vReg[k-1]) begin
// //                     xReg[k] <= nr_step_q6_26_q0_16(xReg[k-1], aReg[k-1]);
// //                     aReg[k] <= aReg[k-1];
// //                     vReg[k] <= 1'b1;
// //                 end else begin
// //                     xReg[k] <= '0;
// //                     aReg[k] <= aReg[k-1];
// //                     vReg[k] <= 1'b0;
// //                 end
// //             end
// //         end
// //     endgenerate

// //     // Output
// // assign    o_reciprocal = xReg[ITERATIONS]; // Q0.16
// // assign    o_valid      = vReg[ITERATIONS];
// // endmodule

// module reciprocalNewtonCalcUnsigned#(
//     parameter int IN_WIDTH   = 32,   // Q6.26 input
//     parameter int BIT_WIDTH  = 16,   // Q0.16 output
//     parameter int LUT_SIZE   = 256,
//     parameter int ITERATIONS = 3     // 3 vòng là đủ với Q4.28
// ) (
//     input  logic                 i_clk,
//     input  logic                 i_rst,
//     input  logic                 i_valid,
//     input  logic [IN_WIDTH-1:0]  i_sum,         // Q6.26, unsigned
//     output logic [BIT_WIDTH-1:0] o_reciprocal,  // Q0.16, unsigned
//     output logic                 o_valid
// );

//     // ---- Range cho softmax sum: 1.0 .. 32.0 trong Q6.26 ----
//     localparam logic [31:0] MIN_SUM = 32'd67108864;     // 1.0
//     localparam logic [31:0] MAX_SUM = 32'd2147483648;   // 32.0

//     // ---- LUT reciprocal [1.0 .. 32.0] ----
//     logic [BIT_WIDTH-1:0] lut[LUT_SIZE];
//     initial $readmemh("lut1to32_reciprocal.mem", lut);

//     // ---- Pipeline regs ----
//     logic [7:0]            lut_index;
//     logic [BIT_WIDTH-1:0]  xReg    [ITERATIONS:0];   // x0..xN (Q0.16)
//     logic [IN_WIDTH-1:0]   aReg    [ITERATIONS:0];   // giữ nguyên a (Q6.26)
//     logic                  vReg    [ITERATIONS:0];

//     // Map [1.0..32.0] -> [0..255]
//     always_comb begin
//         if (i_sum <= MIN_SUM)       lut_index = 8'd0;
//         else if (i_sum >= MAX_SUM)  lut_index = 8'd255;
//         else                        lut_index = (i_sum - MIN_SUM) >> 23;
//     end

//     // ---- Stage 0: lấy x0 từ LUT ----
//     always_ff @(posedge i_clk or posedge i_rst) begin
//         if (i_rst) begin
//             xReg[0]   <= '0;
//             aReg[0]   <= '0;
//             vReg[0]   <= 1'b0;
//         end else begin
//             if (i_valid) begin
//                 xReg[0] <= lut[lut_index];  // Q0.16
//                 aReg[0] <= i_sum;           // Q6.26
//             end else begin
//                 xReg[0] <= '0;
//                 aReg[0] <= '0;
//             end
//             vReg[0] <= i_valid;
//         end
//     end

//     // ---- Newton step với Q4.28 intermediate ----
//     function automatic [BIT_WIDTH-1:0] nr_step_q6_26_q0_16_q4_28 (
//         input [BIT_WIDTH-1:0] x_in,     // Q0.16
//         input [IN_WIDTH-1:0]  a_in      // Q6.26
//     );
//         logic [63:0] ax_q6_42;       // a*x (Q6.42)
//         logic [63:0] two_q6_42;      // 2.0 (Q6.42)
//         logic [63:0] corr_q6_42;     // (2 - a*x) (Q6.42)
//         logic [31:0] corr_q4_28;     // Q4.28
//         logic [47:0] xcorr_q4_44;    // Q4.44

//         begin
//             // a*x
//             ax_q6_42   = a_in * x_in;            // Q6.42
//             two_q6_42  = 64'd2 << 42;            // 2.0 (Q6.42)
//             corr_q6_42 = two_q6_42 - ax_q6_42;   // Q6.42

//             // Q6.42 -> Q4.28 (shift 14, làm tròn)
//             corr_q4_28 = (corr_q6_42 + (64'd1 << 13)) >> 14;

//             // x * corr: Q0.16 * Q4.28 = Q4.44
//             xcorr_q4_44 = x_in * corr_q4_28;

//             // Q4.44 -> Q0.16 (shift 28, làm tròn)
//             nr_step_q6_26_q0_16_q4_28 = (xcorr_q4_44 + (1<<27)) >> 28;
//         end
//     endfunction

//     // ---- Các vòng Newton ----
//     genvar k;
// generate
//     for (k = 1; k <= ITERATIONS; k++) begin : gen_nr
//         always_ff @(posedge i_clk or posedge i_rst) begin
//             if (i_rst) begin
//                 xReg[k] <= '0;
//                 vReg[k] <= 1'b0;
//                 if (k < ITERATIONS) aReg[k] <= '0;
//             end else if (vReg[k-1]) begin
//                 xReg[k] <= nr_step_q6_26_q0_16_q4_28(xReg[k-1], aReg[k-1]);
//                 vReg[k] <= 1'b1;
//                 if (k < ITERATIONS) aReg[k] <= aReg[k-1];
//             end else begin
//                 xReg[k] <= '0;
//                 vReg[k] <= 1'b0;
//                 if (k < ITERATIONS) aReg[k] <= '0;
//             end
//         end
//     end
// endgenerate


//     // ---- Output ----
//     assign o_reciprocal = xReg[ITERATIONS]; // Q0.16
//     assign o_valid      = vReg[ITERATIONS];

// endmodule




module reciprocalNewtonCalcUnsigned #(
    parameter int IN_WIDTH   = 32,   // Q6.26 input
    parameter int BIT_WIDTH  = 16,   // Q0.16 output
    parameter int LUT_SIZE   = 256,
    parameter int ITERATIONS = 1     // số vòng Newton
) (
    input  logic                 i_clk,
    input  logic                 i_rst,
    input  logic                 i_valid,
    input  logic [IN_WIDTH-1:0]  i_sum,         // Q6.26, unsigned
    output logic [BIT_WIDTH-1:0] o_reciprocal,  // Q0.16, unsigned
    output logic                 o_valid
);

    // ---- Range ----
    localparam logic [31:0] MIN_SUM = 32'd67108864;     // 1.0 (Q6.26)
    localparam logic [31:0] MAX_SUM = 32'd2147483648;   // 32.0 (Q6.26)

    // ---- LUT reciprocal ----
(* rom_style = "block" *)    logic [BIT_WIDTH-1:0] lut[LUT_SIZE];
    initial $readmemh("lut1to32_reciprocal.mem", lut);

    // ---- Pipeline regs ----
    logic [7:0]            lut_index;
    logic [BIT_WIDTH-1:0]  xReg    [ITERATIONS:0];   // x0..xN (Q0.16)
    logic [IN_WIDTH-1:0]   aReg    [ITERATIONS:0];   // giữ nguyên a (Q6.26)
    logic                  vReg    [ITERATIONS:0];

    // Map [1.0..32.0] -> [0..255]
    always_comb begin
        if (i_sum <= MIN_SUM)       lut_index = 8'd0;
        else if (i_sum >= MAX_SUM)  lut_index = 8'd255;
        else                        lut_index = (i_sum - MIN_SUM) >> 23;
    end

    // ---- Stage 0: lấy x0 từ LUT ----
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            xReg[0] <= '0;
            aReg[0] <= '0;
            vReg[0] <= 1'b0;
        end else begin
            if (i_valid) begin
                xReg[0] <= lut[lut_index];  // Q0.16
                aReg[0] <= i_sum;           // Q6.26
            end
            vReg[0] <= i_valid;
        end
    end

    // ---- Newton iteration (3 stage pipeline per iteration) ----
    typedef struct packed {
        logic [BIT_WIDTH-1:0] x;   // Q0.16
        logic [IN_WIDTH-1:0]  a;   // Q6.26
    } nr_state_t;

    nr_state_t state   [ITERATIONS:0];
    nr_state_t stage1  [ITERATIONS:0];
    nr_state_t stage2  [ITERATIONS:0];
    nr_state_t stage3  [ITERATIONS:0];
    logic      v1[ITERATIONS:0], v2[ITERATIONS:0], v3[ITERATIONS:0];

    assign state[0].x = xReg[0];
    assign state[0].a = aReg[0];

    genvar k;
    generate
        for (k = 1; k <= ITERATIONS; k++) begin : gen_nr
            // --- Stage 1: tính a*x ---
            logic [63:0] ax_q6_42;
            always_ff @(posedge i_clk or posedge i_rst) begin
                if (i_rst) begin
                    stage1[k] <= '0;
                    v1[k]     <= 1'b0;
                end else if (vReg[k-1]) begin
                    ax_q6_42  <= state[k-1].a * state[k-1].x;   // Q6.42
                    stage1[k].x <= state[k-1].x;
                    stage1[k].a <= state[k-1].a;
                    v1[k]       <= 1'b1;
                end else v1[k] <= 1'b0;
            end

            // --- Stage 2: tính corr = (2 - a*x) >> 14 ---
logic [31:0] corr_q4_28;
always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        stage2[k] <= '0;
        v2[k]     <= 1'b0;
    end else if (v1[k]) begin
        logic [63:0] two_q6_42;
        logic [63:0] corr_q6_42;

        two_q6_42  = 64'd2 << 42;
        corr_q6_42 = two_q6_42 - ax_q6_42;
        corr_q4_28 <= (corr_q6_42 + (64'd1 << 13)) >> 14;

        stage2[k].x <= stage1[k].x;
        stage2[k].a <= stage1[k].a;
        v2[k]       <= 1'b1;
    end else v2[k] <= 1'b0;
end


            // --- Stage 3: tính x * corr ---
            logic [47:0] xcorr_q4_44;
            always_ff @(posedge i_clk or posedge i_rst) begin
                if (i_rst) begin
                    stage3[k] <= '0;
                    v3[k]     <= 1'b0;
                end else if (v2[k]) begin
                    xcorr_q4_44 = stage2[k].x * corr_q4_28;   // Q4.44
                    stage3[k].x <= (xcorr_q4_44 + (1<<27)) >> 28; // Q0.16
                    stage3[k].a <= stage2[k].a;
                    v3[k]       <= 1'b1;
                end else v3[k] <= 1'b0;
            end

            // propagate state
            always_ff @(posedge i_clk or posedge i_rst) begin
                if (i_rst) begin
                    state[k] <= '0;
                    vReg[k]  <= 1'b0;
                end else begin
                    state[k] <= stage3[k];
                    vReg[k]  <= v3[k];
                end
            end
        end
    endgenerate

    // ---- Output ----
    assign o_reciprocal = state[ITERATIONS].x; // Q0.16
    assign o_valid      = vReg[ITERATIONS];

endmodule
