

module sumFinder32 #(
    parameter N = 32,
    parameter IN_BIT_WIDTH  = 16,  // Q4.12 cho input (signed)
    parameter OUT_BIT_WIDTH = 32   // Q6.26 cho output (unsigned)
) (
    input  logic                          i_clk,
    input  logic                          i_rst,
    input  logic                          i_valid,
    input  logic signed [N-1:0][IN_BIT_WIDTH-1:0] i_data ,  // Q4.12, signed
    output logic        [OUT_BIT_WIDTH-1:0] o_sum,          // Q6.26, unsigned
    output logic                           o_valid
);

    // mở rộng từng phần tử sang Q6.26
    logic [OUT_BIT_WIDTH-1:0] i_data_extended [N-1:0] ;

    // bộ cộng trung gian với guard bits (tối đa 32 * 1.0 = 32.0)
    logic [47:0] sum_comb;  // 48 bit accumulator để chắc chắn không tràn

    always_comb begin
        sum_comb = '0;
        for (int i = 0; i < N; i++) begin
            if (i_data[i] < 0) begin
                i_data_extended[i] = '0;  // clamp âm về 0
            end else begin
                // Q4.12 -> Q6.26 bằng cách shift trái 14 (12→26 frac)
                i_data_extended[i] = { { (OUT_BIT_WIDTH-IN_BIT_WIDTH){1'b0} }, i_data[i] } << 14;
            end
            sum_comb += i_data_extended[i];
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_sum   <= '0;
            o_valid <= 1'b0;
        end else begin
            if (sum_comb > {OUT_BIT_WIDTH{1'b1}}) begin
                o_sum <= {OUT_BIT_WIDTH{1'b1}}; // saturate max
            end else begin
                o_sum <= sum_comb[OUT_BIT_WIDTH-1:0];
            end
            o_valid <= i_valid;
        end
    end

endmodule
