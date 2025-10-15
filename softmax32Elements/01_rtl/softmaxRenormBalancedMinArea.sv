`timescale 1ns / 1ps

module softmaxRenormBalancedMinArea #(
    parameter N = 32,
    parameter BIT_WIDTH = 16,
    parameter ACCUM_WIDTH = 32  // Q6.26 cho total_sum
) (
    input  logic i_clk,
    input  logic i_rst,
    input  logic i_valid,       // Trigger từ softmax core
    input  logic [BIT_WIDTH-1:0] i_data [N-1:0],
    output logic [BIT_WIDTH-1:0] o_normalized [N-1:0],
    output logic o_valid        // Ready khi renorm xong
);

    // Trạng thái FSM
    typedef enum logic [2:0] {
        IDLE  = 3'b000,
        SUM   = 3'b001,
        RECIP = 3'b010,  // Chờ reciprocal
        MUL   = 3'b011,  // Stage nhân
        COMMIT= 3'b100   // Stage ghi kết quả
    } state_t;
    state_t state;

    // Signals
    logic [ACCUM_WIDTH-1:0] total_sum;
    logic [4:0] idx;  // Index 0..31

    // Lưu input softmax
    logic [BIT_WIDTH-1:0] softmax_reg [N-1:0];

    // Reciprocal raw và clear
    logic [BIT_WIDTH-1:0] reciprocal_raw;
    logic [BIT_WIDTH-1:0] reciprocal_clear;
    logic reciprocal_valid;

    // Pipeline cho multiply
    logic [31:0] mul_tmp_q;
    logic [4:0]  idx_q;
    logic        mul_valid_q;

    // Reciprocal module
    reciprocalNewtonCalcUnsigned #(
        .IN_WIDTH(ACCUM_WIDTH),
        .BIT_WIDTH(BIT_WIDTH),
        .LUT_SIZE(256),
        .ITERATIONS(3)
    ) u_reciprocal (
        .i_clk      (i_clk),
        .i_rst      (i_rst),
        .i_valid    (state == SUM && idx == N-1),
        .i_sum      (total_sum),         // Q6.26
        .o_reciprocal(reciprocal_raw),
        .o_valid    (reciprocal_valid)
    );

    assign reciprocal_clear = (i_rst) ? '0 : reciprocal_raw;

    // FSM
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state <= IDLE;
            total_sum <= 0;
            idx <= 0;
            o_valid <= 0;
            mul_tmp_q <= 0;
            idx_q <= 0;
            mul_valid_q <= 0;
            for (int i = 0; i < N; i++) begin
                o_normalized[i] <= 0;
                softmax_reg[i]  <= 0;
            end
        end else begin
            case (state)
                IDLE: begin
                    total_sum <= 0;
                    idx <= 0;
                    o_valid <= 0;
                    mul_valid_q <= 0;
                    if (i_valid) begin
                        // Lưu input (Q0.16)
                        for (int i = 0; i < N; i++) begin
                            softmax_reg[i] <= i_data[i];
                        end
                        state <= SUM;
                    end
                end
                SUM: begin
                    // Cộng dồn Q0.16 -> Q6.26 (shift << 10)
                    total_sum <= total_sum + ({ {(ACCUM_WIDTH-BIT_WIDTH){1'b0}}, softmax_reg[idx] } << 10);
                    if (idx == N-1) begin
                        state <= RECIP;
                        idx <= 0;
                    end else begin
                        idx <= idx + 1;
                    end
                end
                RECIP: begin
                    if (reciprocal_valid) begin
                        state <= MUL;
                        idx   <= 0;
                    end
                end
                MUL: begin
                    if (reciprocal_clear == 0) begin
                        mul_tmp_q    <= 0;
                    end else begin
                        mul_tmp_q    <= softmax_reg[idx] * reciprocal_clear; // Q0.16 * Q0.16 = Q0.32
                    end
                    idx_q       <= idx;
                    mul_valid_q <= 1;
                    state       <= COMMIT;
                end
                COMMIT: begin
                    if (mul_valid_q) begin
                        o_normalized[idx_q] <= mul_tmp_q[31:16]; // Q0.16
                    end
                    mul_valid_q <= 0;
                    if (idx == N-1) begin
                        o_valid <= 1;
                        state   <= IDLE;
                        idx     <= 0;
                    end else begin
                        idx <= idx + 1;
                        state <= MUL;
                    end
                end
            endcase
        end
    end

    // Debug: in kết quả khi hoàn tất
    always_ff @(posedge i_clk) begin
        if (o_valid) begin
            $display("t=%0t | RENORM DONE -> o_normalized=%p", $time, o_normalized);
            real sum = 0;
            for (int i = 0; i < N; i++) begin
                sum += $itor(o_normalized[i]) / 65536.0;
            end
            $display("   SUM after renorm = %f", sum);
        end
    end

endmodule
