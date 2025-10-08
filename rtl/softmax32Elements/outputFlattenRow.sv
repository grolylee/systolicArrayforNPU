// // module outputFlattenRow (
// //     input  logic                  i_clk,
// //     input  logic                  i_rst,
// //     input  logic                  i_valid,
// //     input  logic signed [15:0]    matrix[31:0],   // 1 row (32 giá trị)

// //     output logic                  o_done,
// //     output logic [4:0]            wr_addr,        // chỉ cần 5 bit (0..31)
// //     output logic                  wr_en,
// //     output logic [15:0]           wr_data
// // );

// //     logic [4:0] index; // đếm từ 0..31

// //     always_ff @(posedge i_clk or posedge i_rst) begin
// //         if (i_rst) begin
// //             index   <= 5'd0;
// //             wr_en   <= 1'b0;
// //             wr_addr <= 5'd0;
// //             wr_data <= '0;
// //             o_done  <= 1'b0;
// //         end else if (i_valid && !o_done) begin
// //             wr_en   <= 1'b1;
// //             wr_addr <= index;          // 0..31
// //             wr_data <= matrix[index];  // lấy phần tử tương ứng

// //             if (index == 5'd31) begin
// //                 o_done <= 1'b1;
// //                 // giữ index = 31
// //             end else begin
// //                 index <= index + 5'd1;
// //             end
// //         end else begin
// //             wr_en <= 1'b0;
// //         end
// //     end

// // endmodule


// module outputFlattenRow (
//     input  logic                  i_clk,
//     input  logic                  i_rst,
//     input  logic                  i_valid,
//     input  logic  [15:0]    matrix[31:0],
//     output logic                  o_done,
//     output logic [4:0]            wr_addr,
//     output logic                  wr_en,
//     output logic [15:0]           wr_data
// );

//     logic [4:0] index;
//     logic       processing;

//     initial begin
//         $monitor("Time=%0t: outputFlattenRow: i_valid=%b, index=%0d, wr_en=%b, wr_addr=%0d, wr_data=%0d",
//                  $time, i_valid, index, wr_en, wr_addr, wr_data);
//     end

//     always_ff @(posedge i_clk or posedge i_rst) begin
//         if (i_rst) begin
//             index      <= 5'd0;
//             wr_en      <= 1'b0;
//             wr_addr    <= 5'd0;
//             wr_data    <= '0;
//             o_done     <= 1'b0;
//             processing <= 1'b0;
//         end else begin
//             if (i_valid && !processing && !o_done) begin
//                 processing <= 1'b1;
//             end

//             if (processing && !o_done) begin
//                 wr_en   <= 1'b1;
//                 wr_addr <= index;
//                 wr_data <= matrix[index];

//                 if (index == 5'd31) begin
//                     o_done     <= 1'b1;
//                     processing <= 1'b0;
//                 end else begin
//                     index <= index + 5'd1;
//                 end
//             end else begin
//                 wr_en <= 1'b0;
//             end
//         end
//     end
// endmodule


module outputFlattenRow (
    input  logic                  i_clk,
    input  logic                  i_rst,
    input  logic                  i_valid,
    input  logic [15:0]           matrix[31:0],  // input unpacked
    output logic                  o_done,
    output logic [4:0]            wr_addr,
    output logic                  wr_en,
    output logic [15:0]           wr_data
);

    logic [4:0] index;
    logic       processing;

    // 🛠️ Thêm register để giữ data ổn định
    logic [15:0] matrix_reg[31:0];

    // Capture data on valid
    always_ff @(posedge i_clk) begin
        if (i_valid) begin
            for (int i = 0; i < 32; i++) begin
                matrix_reg[i] <= matrix[i];
            end
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            index      <= 5'd0;
            wr_en      <= 1'b0;
            wr_addr    <= 5'd0;
            wr_data    <= '0;
            o_done     <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (i_valid && !processing && !o_done) begin
                processing <= 1'b1;
                index      <= 0;
            end

            if (processing && !o_done) begin
                wr_en   <= 1'b1;
                wr_addr <= index;
                wr_data <= matrix_reg[index];  // dùng dữ liệu đã register

                if (index == 5'd31) begin
                    o_done     <= 1'b1;
                    processing <= 1'b0;
                end else begin
                    index <= index + 5'd1;
                end
            end else begin
                wr_en <= 1'b0;
            end
        end
    end
endmodule
