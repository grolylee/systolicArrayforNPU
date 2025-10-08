module maxFinder #(
    parameter int BIT_WIDTH = 16,
    parameter int N         = 8,                // số phần tử, yêu cầu N = 2^x
    parameter int STAGES    = $clog2(N)         // số stage = log2(N)
) (
    input  logic                          i_clk,
    input  logic                          i_rst,
    input  logic                          i_valid,
    input  logic signed [N-1:0][BIT_WIDTH-1:0] i_data,  // packed array => Vivado OK
    output logic signed [BIT_WIDTH-1:0]   o_dataMax,
    output logic                          o_valid
);

// latency $clog2(N) + 1 


    // pipeline: stage x phần tử
    logic signed [BIT_WIDTH-1:0] pipeline   [STAGES:0][N-1:0];
    logic        [STAGES:0]      valid_pipeline;

    // stage 0 load input
    always_comb begin
        for (int i = 0; i < N; i++) begin
            pipeline[0][i] = i_data[i];
        end
        valid_pipeline[0] = i_valid;
    end

    // các stage so sánh cặp
    for (genvar stage = 0; stage < STAGES; stage++) begin : pipeline_stages
        always_ff @(posedge i_clk or posedge i_rst) begin
            if (i_rst) begin
                for (int i = 0; i < N; i++) begin
                    pipeline[stage+1][i] <= '0;
                end
                valid_pipeline[stage+1] <= 1'b0;
            end else begin
                for (int i = 0; i < N/(2**(stage+1)); i++) begin
                    pipeline[stage+1][i] <= (pipeline[stage][2*i] > pipeline[stage][2*i+1])
                                          ? pipeline[stage][2*i]
                                          : pipeline[stage][2*i+1];
                end
                valid_pipeline[stage+1] <= valid_pipeline[stage];
            end
        end
    end

    // output
    assign o_dataMax = pipeline[STAGES][0];
    assign o_valid   = valid_pipeline[STAGES];

endmodule
