module bugSoftmax32 #(
    parameter int N = 32,
    parameter int BIT_WIDTH = 16
)(
    input  logic                        i_clk,
    input  logic                        i_rst,
    input  logic                        i_valid,
    input  logic signed [BIT_WIDTH-1:0] i_data [N-1:0],   // Q2.14

    output logic                        o_valid,
    output logic [BIT_WIDTH-1:0]        o_data  [N-1:0]  // Q0.16 unsigned
);

    // =========================================================
    // Parameters
    // =========================================================
    localparam LAT_MAXF = $clog2(N)+1;  // tăng thêm 1 để khớp row
// =========================================================
// =========================================================
// Stage 0: Input pipeline để align với maxVal
// =========================================================
logic signed [BIT_WIDTH-1:0] data_pipe [LAT_MAXF:0][N-1:0];

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        for (int d=0; d<=LAT_MAXF; d++)
            for (int j=0; j<N; j++)
                data_pipe[d][j] <= '0;
    end else begin
        data_pipe[0] <= i_data;
        for (int d=1; d<=LAT_MAXF; d++)
            data_pipe[d] <= data_pipe[d-1];
    end
end

// Debug khi nhận input mới
always_ff @(posedge i_clk) begin
    if (i_valid) begin
        $display("t=%0t | NEW INPUT -> data_pipe[0] = %p",
                 $time, i_data);
    end
end

// =========================================================
// Stage 1: MaxFinder
// =========================================================
logic signed [BIT_WIDTH-1:0] valueMaxFinder;
logic validMax;

maxFinder #(
    .BIT_WIDTH(BIT_WIDTH), .N(N)
) u_maxFinder (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_valid(i_valid),
    .i_data(i_data),
    .o_dataMax(valueMaxFinder),
    .o_valid(validMax)
);

// Delay validMax + register lại valueMaxFinder
logic validMax_d;
logic signed [BIT_WIDTH-1:0] valueMaxFinder_d, valueMaxFinder_dd;

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        validMax_d        <= 0;
        valueMaxFinder_d  <= '0;
        valueMaxFinder_dd <= '0;
    end else begin
        validMax_d       <= validMax;
        if (validMax) begin
            valueMaxFinder_d <= valueMaxFinder;
        end
        // thêm 1 chu kỳ delay nữa
        valueMaxFinder_dd <= valueMaxFinder_d;
    end
end

logic validMax_dd;
always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        validMax_dd <= 0;
    end else begin
        validMax_dd <= validMax_d;
    end
end

always_ff @(posedge i_clk) begin
    if (validMax) begin
        $display("t=%0t | STAGE1 MaxFinder maxVal=%0d, data_pipe[LAT_MAXF]=%p",
                 $time, valueMaxFinder, data_pipe[LAT_MAXF]);
    end
end

// =========================================================
// Stage 2: Subtractor
// =========================================================
logic signed [BIT_WIDTH-1:0] sub_data [N-1:0];
logic signed [BIT_WIDTH-1:0] sub_data_d[N-1:0];
logic validSub;
logic validSub_d;

subtractorHS #(
    .BIT_WIDTH(BIT_WIDTH), .N(N)
) u_sub (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_valid(validMax_dd),             // valid đã align
    .i_data(data_pipe[LAT_MAXF]),     // dữ liệu đã align
    .i_maxValue(valueMaxFinder_dd),   // maxVal delay thêm 1 chu kỳ
    .o_data(sub_data),
    .o_valid(validSub)
);
always_ff @(posedge i_clk) begin
    if (validSub) begin
        $display("t=%0t | STAGE2 in_aligned=%p, maxVal=%0d, sub_out=%p",
                 $time, data_pipe[LAT_MAXF], valueMaxFinder_dd, sub_data);
    end
end


    // =========================================================
    // Stage 3: ExpCalculator song song
    // =========================================================
    logic signed [N-1:0][BIT_WIDTH-1:0] exp_data ;
    logic validExp [N-1:0];
    logic validExpAll;

    always_comb begin
        validExpAll = 1'b1;
        for (int i=0; i<N; i++) validExpAll &= validExp[i];
    end
    

    for (genvar i=0; i<N; i++) begin : gen_exp
        expCalculator u_exp (
            .i_clk(i_clk),
            .i_rst(i_rst),
            .i_valid(validSub),
            .i_data(sub_data[i]),
            .o_exp(exp_data[i]),
            .o_valid(validExp[i])
        );
    end

    always_ff @(posedge i_clk) begin
        if (validExpAll) begin
            $display("t=%0t | STAGE3 ExpCalc exp_data=%p", $time, exp_data);
        end
    end

    // =========================================================
    // Stage 4: SumFinder
    // =========================================================
    logic signed [31:0] sumExp;
    logic validSum;

    sumFinder32 #(
        .N(N)
    ) u_sumFinder (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(validExpAll),
        .i_data(exp_data),
        .o_sum(sumExp),
        .o_valid(validSum)
    );

    always_ff @(posedge i_clk) begin
        if (validSum) begin
            $display("t=%0t | STAGE4 SumFinder sumExp=%0d", $time, sumExp);
        end
    end

    // =========================================================
    // Stage 5: Reciprocal
    // =========================================================
    logic [BIT_WIDTH-1:0] recipVal;   // Q0.16 unsigned
    logic validRecip;

    reciprocalNewtonCalcUnsigned u_recip (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(validSum),
        .i_sum(sumExp),
        .o_reciprocal(recipVal),
        .o_valid(validRecip)
    );

    always_ff @(posedge i_clk) begin
        if (validRecip) begin
            $display("t=%0t | STAGE5 Reciprocal recipVal=%0d", $time, recipVal);
        end
    end

    // =========================================================
    // Stage 6: Multiply exp * recip
    // =========================================================
    logic [BIT_WIDTH-1:0] o_data_unsigned [N-1:0];

    for (genvar i=0; i<N; i++) begin : gen_mult
        multiplierDivisionUnsigned #(
            .BIT_WIDTH(BIT_WIDTH)
        ) u_mult (
            .i_valid(validRecip),
            .i_dataA(exp_data[i]),     // Q4.12 signed
            .i_dataB(recipVal),        // Q0.16 unsigned
            .o_data(o_data_unsigned[i]),
            .o_valid()                 // bỏ qua per-lane valid
        );
    end

    assign o_valid = validRecip;

    always_comb begin
        for (int i=0; i<N; i++) begin
            o_data[i] = o_data_unsigned[i]; // output Q0.16 unsigned
        end
    end

    always_ff @(posedge i_clk) begin
        if (o_valid) begin
            $display("t=%0t | OUTPUT o_data=%p", $time, o_data);
        end
    end


endmodule
