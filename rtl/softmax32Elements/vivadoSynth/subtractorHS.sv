module subtractorHS #(
    parameter int BIT_WIDTH = 16,
    parameter int N         = 32,
    parameter int STAGES    = $clog2(N)
) (
    input  logic                          i_clk,
    input  logic                          i_rst,
    input  logic                          i_valid,
    input  logic signed [N-1:0][BIT_WIDTH-1:0] i_data ,   // Q2.14
    output logic signed [N-1:0][BIT_WIDTH-1:0] o_data ,   // Q4.12
    output logic                          o_valid
);

    // ====================================
    // === Internal signals for maxFinder ===
    // ====================================
    logic signed [BIT_WIDTH-1:0] maxValue;
    logic                        max_valid;

    // ====================================
    // === Register input data when valid ===
    // ====================================
    logic signed [BIT_WIDTH-1:0] i_data_reg [N-1:0];

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (int i = 0; i < N; i++) begin
                i_data_reg[i] <= '0;
            end
        end else if (i_valid) begin
            for (int i = 0; i < N; i++) begin
                i_data_reg[i] <= i_data[i];
            end
        end
    end

    // ====================================
    // === Instance of maxFinder ===
    // ====================================
    maxFinder #(
        .BIT_WIDTH(BIT_WIDTH),
        .N(N),
        .STAGES(STAGES)
    ) u_maxFinder (
        .i_clk     (i_clk),
        .i_rst     (i_rst),
        .i_valid   (i_valid),
        .i_data    (i_data),
        .o_dataMax (maxValue),
        .o_valid   (max_valid)
    );

    // ====================================
    // === Subtraction logic ===
    // ====================================
    logic signed [BIT_WIDTH-1:0] sub_reg  [N-1:0];
    logic                        validReg;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (int i = 0; i < N; i++) begin
                sub_reg[i] <= '0;
            end
            validReg <= 1'b0;
        end else if (max_valid) begin
            $display("\n=== [@%0t] maxFinder result valid ===", $time);
            $display("  -> maxValue (Q2.14) = %0d = %f", maxValue, maxValue / 16384.0);

            for (int i = 0; i < N; i++) begin
                sub_reg[i] <= i_data_reg[i] - maxValue;
                $display("  i_data[%0d] = %0d (%f) --> sub = %0d",
                    i, i_data_reg[i], i_data_reg[i] / 16384.0, i_data_reg[i] - maxValue);
            end
            validReg <= 1'b1;
        end else begin
            validReg <= 1'b0;
        end
    end

    // ====================================
    // === Shift result (Q2.14 → Q4.12) ===
    // ====================================
    always_comb begin
        for (int i = 0; i < N; i++) begin
            // Dịch phải có dấu (chia 4): Q2.14 -> Q4.12
            o_data[i] = $signed(sub_reg[i]) >>> 2;
        end
    end

    assign o_valid = validReg;

    // ====================================
    // === Display kết quả cuối ===
    // ====================================
    always_ff @(posedge i_clk) begin
        if (o_valid) begin
            $display("\n=== [@%0t] o_valid ===", $time);
            for (int i = 0; i < N; i++) begin
                $display("  o_data[%0d] = %0d (Q4.12) = %f",
                    i, o_data[i], o_data[i] / 4096.0);
            end
        end
    end

endmodule
