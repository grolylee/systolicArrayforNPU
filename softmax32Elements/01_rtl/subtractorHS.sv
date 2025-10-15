module subtractorHS #(
    parameter int BIT_WIDTH = 16,
    parameter int N = 32
) (
    input  logic                        i_clk,
    input  logic                        i_rst,
    input  logic                        i_valid,
    input  logic signed [BIT_WIDTH-1:0] i_data [N-1:0],   // Q2.14
    input  logic signed [BIT_WIDTH-1:0] i_maxValue,       // Q2.14
    output logic signed [BIT_WIDTH-1:0] o_data [N-1:0],   // Q4.12
    output logic                        o_valid
);

    // Register input
    logic signed [BIT_WIDTH-1:0] i_dataReg [N-1:0] ;
    logic signed [BIT_WIDTH-1:0] maxValueReg;
    logic signed [BIT_WIDTH-1:0] sub_data [N-1:0] ;  // Q2.14
    logic                        validReg;

    // Latch input và tính toán
    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            for (int i = 0; i < N; i++) begin
                i_dataReg[i] <= '0;
                sub_data[i]  <= '0;
            end
            maxValueReg <= '0;
            validReg    <= 0;
        end else if (i_valid) begin
            // lưu input và max
            for (int i = 0; i < N; i++) begin
                i_dataReg[i] <= i_data[i];
            end
            maxValueReg <= i_maxValue;
            validReg    <= 1;

            // tính toán subtraction từ dữ liệu đã register (đồng bộ)
            for (int i = 0; i < N; i++) begin
                sub_data[i] <= i_data[i] - i_maxValue;
            end
        end else begin
            validReg <= 0;
        end
    end


    always_ff @(posedge i_clk) begin 
                for (int i = 0; i < N; i++) begin
            // o_data[i] = sub_data[i] >>> 2;
            o_data[i] <= sub_data[i] >>> 2;
            o_valid <= validReg;
        end
    end
endmodule
    // Chuyển Q2.14 -> Q4.12
    // always_comb begin
    //     for (int i = 0; i < N; i++) begin
    //         // o_data[i] = sub_data[i] >>> 2;
    //         o_data[i] = sub_data[i] >>> 2;
    //     end
    // end

    // assign o_valid = validReg;

// endmodule
