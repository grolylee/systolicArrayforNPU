

// module sumFinder32 #(
//     parameter N = 32,
//     parameter IN_BIT_WIDTH  = 16,  // Q4.12 cho input (signed)
//     parameter OUT_BIT_WIDTH = 32   // Q6.26 cho output (unsigned)
// ) (
//     input  logic                          i_clk,
//     input  logic                          i_rst,
//     input  logic                          i_valid,
//     input  logic signed [IN_BIT_WIDTH-1:0] i_data [N-1:0],  // Q4.12, signed
//     output logic        [OUT_BIT_WIDTH-1:0] o_sum,          // Q6.26, unsigned
//     output logic                           o_valid
// );

//     // mở rộng từng phần tử sang Q6.26
//     logic [OUT_BIT_WIDTH-1:0] i_data_extended [N-1:0] ;

//     // bộ cộng trung gian với guard bits (tối đa 32 * 1.0 = 32.0)
//     logic [47:0] sum_comb;  // 48 bit accumulator để chắc chắn không tràn

//     always_comb begin
//         sum_comb = '0;
//         for (int i = 0; i < N; i++) begin
//             if (i_data[i] < 0) begin
//                 i_data_extended[i] = '0;  // clamp âm về 0
//             end else begin
//                 // Q4.12 -> Q6.26 bằng cách shift trái 14 (12→26 frac)
//                 i_data_extended[i] = { { (OUT_BIT_WIDTH-IN_BIT_WIDTH){1'b0} }, i_data[i] } << 14;
//             end
//             sum_comb += i_data_extended[i];
//         end
//     end

//     always_ff @(posedge i_clk or posedge i_rst) begin
//         if (i_rst) begin
//             o_sum   <= '0;
//             o_valid <= 1'b0;
//         end else begin
//             if (sum_comb > {OUT_BIT_WIDTH{1'b1}}) begin
//                 o_sum <= {OUT_BIT_WIDTH{1'b1}}; // saturate max
//             end else begin
//                 o_sum <= sum_comb[OUT_BIT_WIDTH-1:0];
//             end
//             o_valid <= i_valid;
//         end
//     end

// endmodule


module sumFinder32 #(
    parameter N = 4,
    parameter IN_BIT_WIDTH  = 16,  // Q4.12 input
    parameter OUT_BIT_WIDTH = 32   // Q6.26 output
) (
    input  logic                           i_clk,
    input  logic                           i_rst,
    input  logic                           i_valid,
    input  logic signed [IN_BIT_WIDTH-1:0] i_data [N-1:0],
    output logic        [OUT_BIT_WIDTH-1:0] o_sum,
    output logic                           o_valid
);

    // stage 0: clamp âm -> unsigned, shift sang Q6.26
    logic [OUT_BIT_WIDTH-1:0] stage0 [N-1:0];
    always_comb begin
        for (int i = 0; i < N; i++) begin
            if (i_data[i] < 0) stage0[i] = '0;
            else               stage0[i] = { {(OUT_BIT_WIDTH-IN_BIT_WIDTH){1'b0}}, i_data[i]} << 14;
        end
    end

    // pipeline registers
    logic [OUT_BIT_WIDTH-1:0] stage1 [N/2-1:0];
    logic [OUT_BIT_WIDTH-1:0] stage2 [N/4-1:0];
    logic [OUT_BIT_WIDTH-1:0] stage3 [N/8-1:0];
    logic [OUT_BIT_WIDTH-1:0] stage4 [N/16-1:0];
    logic [OUT_BIT_WIDTH-1:0] stage5;

    logic v1,v2,v3,v4,v5;

    // stage 1
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (int i=0;i<N/2;i++) stage1[i] <= '0;
            v1 <= 1'b0;
        end else begin
            v1 <= i_valid;
            for (int i=0;i<N/2;i++) stage1[i] <= stage0[2*i] + stage0[2*i+1];
        end
    end

    // stage 2
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (int i=0;i<N/4;i++) stage2[i] <= '0;
            v2 <= 1'b0;
        end else begin
            v2 <= v1;
            for (int i=0;i<N/4;i++) stage2[i] <= stage1[2*i] + stage1[2*i+1];
        end
    end

    // stage 3
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (int i=0;i<N/8;i++) stage3[i] <= '0;
            v3 <= 1'b0;
        end else begin
            v3 <= v2;
            for (int i=0;i<N/8;i++) stage3[i] <= stage2[2*i] + stage2[2*i+1];
        end
    end

    // stage 4
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (int i=0;i<N/16;i++) stage4[i] <= '0;
            v4 <= 1'b0;
        end else begin
            v4 <= v3;
            for (int i=0;i<N/16;i++) stage4[i] <= stage3[2*i] + stage3[2*i+1];
        end
    end

    // stage 5 (final)
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            stage5 <= '0;
            v5     <= 1'b0;
        end else begin
            v5     <= v4;
            stage5 <= stage4[0] + stage4[1];
        end
    end

    // output
    assign o_sum   = stage5;
    assign o_valid = v5;

endmodule
