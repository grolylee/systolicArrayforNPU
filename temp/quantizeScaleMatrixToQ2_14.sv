// Quantize + scale matrix for Self-Attention
// Input:  Q18.14 (32-bit) from SA
// Output: Q2.14  (16-bit) for softmax
module quantizeScaleMatrixToQ2_14 #(
    parameter int ROWS = 32,
    parameter int COLS = 32,
    parameter int INPUT_BIT_WIDTH  = 32, // Q18.14
    parameter int OUTPUT_BIT_WIDTH = 16  // Q2.14
) (
    input  logic i_clk,
    input  logic i_rst,
    input  logic i_valid,
    input  logic signed [ROWS-1:0][COLS-1:0][INPUT_BIT_WIDTH-1:0] i_matrix,
    output logic signed [ROWS-1:0][COLS-1:0][OUTPUT_BIT_WIDTH-1:0] o_matrix,
    output logic o_valid
);

    // Intermediate
    logic signed [INPUT_BIT_WIDTH-1:0] scaled   [ROWS][COLS];
    logic signed [OUTPUT_BIT_WIDTH-1:0] narrowed [ROWS][COLS];
    logic signed [OUTPUT_BIT_WIDTH-1:0] clipped  [ROWS][COLS];

    // Combinational: scale + narrow + clip
    always_comb begin
        for (int r = 0; r < ROWS; r++) begin
            for (int c = 0; c < COLS; c++) begin
                // Scale by 1/8 = >>3, still Q18.14
                scaled[r][c] = i_matrix[r][c] >>> 3;

                // Downsize to 16-bit (Q2.14), auto sign extend
                narrowed[r][c] = $signed(scaled[r][c][15:0]);

                // Clip to Q2.14 range [-32768, +32767]
                if (narrowed[r][c] >  32767)
                    clipped[r][c] =  32767;
                else if (narrowed[r][c] < -32768)
                    clipped[r][c] = -32768;
                else
                    clipped[r][c] = narrowed[r][c];
            end
        end
    end

    // Sequential: register outputs
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_valid <= 1'b0;
            for (int r = 0; r < ROWS; r++)
                for (int c = 0; c < COLS; c++)
                    o_matrix[r][c] <= '0;
        end else begin
            o_valid <= i_valid;
            for (int r = 0; r < ROWS; r++)
                for (int c = 0; c < COLS; c++)
                    o_matrix[r][c] <= clipped[r][c];
        end
    end

endmodule