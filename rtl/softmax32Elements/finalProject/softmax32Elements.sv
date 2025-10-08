//// // // `timescale 1ns / 1ps

//// // // module softmax32Elements (
//// // //     input logic i_clk,
//// // //     input logic i_rst,  // Active-high reset
//// // //     input logic i_start,
//// // //     output logic o_validResult
//// // // );

//// // //     logic signed [15:0]  i_data[31:0];
//// // //     logic signed [15:0] o_softmax[31:0];  // Đổi thành 32-bit

//// // //     logic bramDone;
//// // //     logic        wr_en;
//// // //     logic [4:0]  wr_addr;
//// // //     logic [15:0] wr_data;  // Đổi thành 32-bit

//// // //     topBramWrapper u_Bram (
//// // //         .i_clk(i_clk),
//// // //         .i_rst(i_rst),
//// // //         .i_start(i_start),
//// // //         .o_row(i_data),
//// // //         .o_done(bramDone)
//// // //     );

//// // //     bugSoftmax32 #(
//// // //         .N(32),
//// // //         .BIT_WIDTH(16)
//// // //     ) u_softmax (
//// // //         .i_clk(i_clk),
//// // //         .i_rst(i_rst),
//// // //         .i_valid(bramDone),
//// // //         .i_data(i_data),
//// // //         .o_data(o_softmax),
//// // //         .o_valid(o_validResult)
//// // //     );

//// // //     outputFlattenRow u_output_flatten (
//// // //         .i_clk(i_clk),
//// // //         .i_rst(i_rst),
//// // //         .i_valid(bramDone),
//// // //         .matrix(o_softmax),
//// // //         .o_done(),
//// // //         .wr_addr(wr_addr),
//// // //         .wr_en(wr_en),
//// // //         .wr_data(wr_data)
//// // //     );

//// // //     blk_mem_gen_out u_bram_out (
//// // //         .clka(i_clk),
//// // //         .ena(1'b1),
//// // //         .wea(wr_en),
//// // //         .addra(wr_addr),
//// // //         .dina(wr_data),  // Nhận wr_data 32-bit
//// // //         .clkb(i_clk),
//// // //         .enb(1'b1),
//// // //         .web(1'b0),
//// // //         .addrb(10'b0),
//// // //         .dinb(16'b0),
//// // //         .doutb()
//// // //     );

//// // // endmodule


//// // `timescale 1ns / 1ps

//// // module softmax32Elements (
//// //     input  logic i_clk,
//// //     input  logic i_rst,         // Active-high reset
//// //     input  logic i_start,
//// //     output logic o_validResult
//// // );

//// //     logic signed [15:0]  i_data[31:0];
//// //     logic signed [15:0]  o_softmax[31:0];  // Q0.16
//// //     logic bramDone;

//// //     logic        wr_en;
//// //     logic [4:0]  wr_addr;
//// //     logic [15:0] wr_data;

//// //     logic [4:0]  rd_addr;
//// //     logic [15:0] rd_data;

//// //     // --- BRAM Reader ---
//// //     topBramWrapper u_Bram (
//// //         .i_clk  (i_clk),
//// //         .i_rst  (i_rst),
//// //         .i_start(i_start),
//// //         .o_row  (i_data),
//// //         .o_done (bramDone)
//// //     );

//// //     // --- Softmax ---
//// //     bugSoftmax32 #(
//// //         .N(32),
//// //         .BIT_WIDTH(16)
//// //     ) u_softmax (
//// //         .i_clk   (i_clk),
//// //         .i_rst   (i_rst),
//// //         .i_valid (bramDone),
//// //         .i_data  (i_data),
//// //         .o_data  (o_softmax),
//// //         .o_valid (o_validResult)
//// //     );

//// //     // --- Flatten + Write control ---
//// //     outputFlattenRow u_output_flatten (
//// //         .i_clk   (i_clk),
//// //         .i_rst   (i_rst),
//// //         .i_valid (bramDone),
//// //         .matrix  (o_softmax),
//// //         .o_done  (),
//// //         .wr_addr (wr_addr),
//// //         .wr_en   (wr_en),
//// //         .wr_data (wr_data)
//// //     );

//// //     // --- BRAM Output (simple model) ---
//// //     logic [15:0] bram_mem [0:31];
//// //     always_ff @(posedge i_clk) begin
//// //         if (wr_en)
//// //             bram_mem[wr_addr] <= wr_data;
//// //         rd_data <= bram_mem[rd_addr];
//// //     end

//// // endmodule


//// `timescale 1ns / 1ps

//// module softmax32Elements (
////     input  logic i_clk,
////     input  logic i_rst,
////     input  logic i_start,
////     output logic o_validResult,
////     output logic o_done
//// );

////     // --- Internal signals ---
////     logic signed [15:0]  i_data[31:0];     // input row từ BRAM input
////     logic  [15:0]  o_softmax[31:0];  // output softmax (Q0.16)
////     logic                bramDone;

////     // Ghi BRAM output
////     logic        wr_en;
////     logic [4:0]  wr_addr;
////     logic [15:0] wr_data;
////     logic        flatten_done;

////     // --- BRAM Reader ---
////     topBramWrapper u_Bram (
////         .i_clk  (i_clk),
////         .i_rst  (i_rst),
////         .i_start(i_start),
////         .o_row  (i_data),
////         .o_done (bramDone)
////     );

////     // --- Softmax core ---
////     bugSoftmax32 #(
////         .N(32),
////         .BIT_WIDTH(16)
////     ) u_softmax (
////         .i_clk   (i_clk),
////         .i_rst   (i_rst),
////         .i_valid (bramDone),
////         .i_data  (i_data),
////         .o_data  (o_softmax),
////         .o_valid (o_validResult)
////     );

////     // --- Flatten + Write control ---
////     outputFlattenRow u_output_flatten (
////         .i_clk   (i_clk),
////         .i_rst   (i_rst),
////         .i_valid (o_validResult),  // ghi khi softmax xong
////         .matrix  (o_softmax),
////         .o_done  (flatten_done),   // báo hiệu ghi xong
////         .wr_addr (wr_addr),
////         .wr_en   (wr_en),
////         .wr_data (wr_data)
////     );

////     assign o_done = flatten_done;

////     // --- BRAM Output (Vivado IP) ---
////     blk_mem_gen_out u_bram_out (
////         .clka   (i_clk),
////         .ena    (1'b1),
////         .wea    (wr_en),
////         .addra  (wr_addr),
////         .dina   (wr_data),
////         .clkb   (i_clk),
////         .enb    (1'b1),
////         .web    (1'b0),
////         .addrb  (),      // testbench sẽ truy cập trực tiếp
////         .dinb   (16'b0),
////         .doutb  ()       // testbench sẽ đọc trực tiếp
////     );

//// endmodule


// `timescale 1ns / 1ps

// module softmax32Elements (
//     input  logic i_clk,
//     input  logic i_rst,
//     input  logic i_start,
//     output logic o_validResult,
//     output logic o_done,

//     // 👇 thêm cổng debug để giữ BRAM output
//     output logic [15:0] o_probe_doutb
// );


module softmax32Elements (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_start,
    output logic        o_validResult,
    output logic        o_done,

    // 👇 debug cổng read BRAM
    input  logic [4:0]  i_probe_addr,
    output logic [15:0] o_probe_doutb
);

    // --- Internal signals ---
    logic signed [15:0]  i_data[31:0];     // input row từ BRAM input
    logic        [15:0]  o_softmax[31:0];  // output softmax (Q0.16)
    logic                bramDone;

    // Ghi BRAM output
    logic        wr_en;
    logic [4:0]  wr_addr;
    logic [15:0] wr_data;
    logic        flatten_done;

    // --- BRAM Reader ---
    topBramWrapper u_Bram (
        .i_clk  (i_clk),
        .i_rst  (i_rst),
        .i_start(i_start),
        .o_row  (i_data),
        .o_done (bramDone)
    );

    // --- Softmax core ---
    bugSoftmax32 #(
        .N(32),
        .BIT_WIDTH(16)
    ) u_softmax32 (
        .i_clk   (i_clk),
        .i_rst   (i_rst),
        .i_valid (bramDone),
        .i_data  (i_data),
        .o_data  (o_softmax),
        .o_valid (o_validResult)
    );

    // --- Flatten + Write control ---
    outputFlattenRow u_output_flatten (
        .i_clk   (i_clk),
        .i_rst   (i_rst),
        .i_valid (o_validResult),  // ghi khi softmax xong
        .matrix  (o_softmax),
        .o_done  (flatten_done),   // báo hiệu ghi xong
        .wr_addr (wr_addr),
        .wr_en   (wr_en),
        .wr_data (wr_data)
    );

    assign o_done = flatten_done;

    // --- BRAM Output (Vivado IP) ---
    blk_mem_gen_out u_bram_out (
        .clka   (i_clk),
        .ena    (1'b1),
        .wea    (wr_en),
        .addra  (wr_addr),
        .dina   (wr_data),
        .clkb   (i_clk),
        .enb    (1'b1),
        .web    (1'b0),
        .addrb  (i_probe_addr),
        .dinb   (16'b0),
        .doutb  (o_probe_doutb)   //  route ra ngoài, tránh bị optimize
    );

endmodule



// tb tren nay dang dung chi la chua renorm












































// ow tren dang dung chi la sai so cao 









// `timescale 1ns / 1ps

// module softmax32Elements (
//     input  logic i_clk,
//     input  logic i_rst,
//     input  logic i_start,
//     output logic o_validResult,
//     output logic o_done,

//     // 👇 thêm cổng debug để giữ BRAM output
//     output logic [15:0] o_probe_doutb
// );

//     // --- Internal signals ---
//     logic signed [15:0]  i_data[31:0];           // input row từ BRAM input
//     logic        [15:0]  o_softmax[31:0];        // output softmax ban đầu (Q0.16)
//     logic        [15:0]  o_normalized[31:0];     // output sau renorm (tổng=1)
//     logic                bramDone;
//     logic                softmax_valid;          // Valid từ softmax core
//     logic                renorm_valid;           // Valid từ renorm

//     // Ghi BRAM output
//     logic        wr_en;
//     logic [4:0]  wr_addr;
//     logic [15:0] wr_data;
//     logic        flatten_done;

//     // --- BRAM Reader ---
//     topBramWrapper u_Bram (
//         .i_clk  (i_clk),
//         .i_rst  (i_rst),
//         .i_start(i_start),
//         .o_row  (i_data),
//         .o_done (bramDone)
//     );

//     // --- Softmax core ---
//     bugSoftmax32 #(
//         .N(32),
//         .BIT_WIDTH(16)
//     ) u_softmax32 (
//         .i_clk   (i_clk),
//         .i_rst   (i_rst),
//         .i_valid (bramDone),
//         .i_data  (i_data),
//         .o_data  (o_softmax),
//         .o_valid (softmax_valid)  // Đổi tên để rõ
//     );

//     // --- Renormalization mới 👇 ---
//     softmaxRenormBalancedMinArea #(
//         .N(32),
//         .BIT_WIDTH(16)
//     ) u_renorm (
//         .i_clk      (i_clk),
//         .i_rst      (i_rst),
//         .i_valid    (softmax_valid),
//         .i_data     (o_softmax),
//         .o_normalized (o_normalized),
//         .o_valid    (renorm_valid)
//     );

//     // --- Flatten + Write control (sử dụng o_normalized thay vì o_softmax) ---
//     outputFlattenRow u_output_flatten (
//         .i_clk   (i_clk),
//         .i_rst   (i_rst),
//         .i_valid (renorm_valid),  // Trigger từ renorm thay vì softmax
//         .matrix  (o_normalized),  // Sử dụng normalized output
//         .o_done  (flatten_done),  // báo hiệu ghi xong
//         .wr_addr (wr_addr),
//         .wr_en   (wr_en),
//         .wr_data (wr_data)
//     );

//     assign o_validResult = renorm_valid;  // Update valid signal
//     assign o_done = flatten_done;

//     // --- BRAM Output (Vivado IP) ---
//     blk_mem_gen_out u_bram_out (
//         .clka   (i_clk),
//         .ena    (1'b1),
//         .wea    (wr_en),
//         .addra  (wr_addr),
//         .dina   (wr_data),
//         .clkb   (i_clk),
//         .enb    (1'b1),
//         .web    (1'b0),
//         .addrb  (),
//         .dinb   (16'b0),
//         .doutb  (o_probe_doutb)   // route ra ngoài, tránh bị optimize
//     );
// 
// endmodule

















//`timescale 1ns / 1ps

//module softmax32Elements (
//    input  logic i_clk,
//    input  logic i_rst,
//    input  logic i_start,
//    output logic o_validResult,
//    output logic o_done,

//    // debug output để xem dữ liệu từ BRAM_out
//    output logic [15:0] o_probe_doutb
//);

//    // --- Internal signals ---
//    logic signed [15:0]  i_data[31:0]; 
//    logic        [15:0]  o_softmax[31:0];
//    logic                bramDone;

//    logic        wr_en;
//    logic [4:0]  wr_addr;
//    logic [15:0] wr_data;
//    logic        flatten_done;

//    // --- BRAM Reader ---
//    topBramWrapper u_Bram (
//        .i_clk  (i_clk),
//        .i_rst  (i_rst),
//        .i_start(i_start),
//        .o_row  (i_data),
//        .o_done (bramDone)
//    );

//    // --- Softmax core ---
//    bugSoftmax32 #(
//        .N(32),
//        .BIT_WIDTH(16)
//    ) u_softmax32 (
//        .i_clk   (i_clk),
//        .i_rst   (i_rst),
//        .i_valid (bramDone),
//        .i_data  (i_data),
//        .o_data  (o_softmax),
//        .o_valid (o_validResult)
//    );

//    // --- Flatten + Write control ---
//    outputFlattenRow u_output_flatten (
//        .i_clk   (i_clk),
//        .i_rst   (i_rst),
//        .i_valid (o_validResult), 
//        .matrix  (o_softmax),
//        .o_done  (flatten_done),  
//        .wr_addr (wr_addr),
//        .wr_en   (wr_en),
//        .wr_data (wr_data)
//    );

//    assign o_done = flatten_done;

//    // --- BRAM Output (Vivado IP) ---
//    logic [4:0] probe_addr;
//    logic       reading;
//    logic [5:0] read_count; // đếm từ 0..31

//    always_ff @(posedge i_clk or posedge i_rst) begin
//        if (i_rst) begin
//            probe_addr <= '0;
//            read_count <= '0;
//            reading    <= 1'b0;
//        end else begin
//            if (flatten_done) begin
//                // reset counter và bắt đầu đọc lại 32 giá trị
//                probe_addr <= '0;
//                read_count <= '0;
//                reading    <= 1'b1;
//            end else if (reading) begin
//                probe_addr <= probe_addr + 1;
//                read_count <= read_count + 1;
//                if (read_count == 31) begin
//                    reading <= 1'b0; // đọc xong 32 phần tử
//                end
//            end
//        end
//    end

//    blk_mem_gen_out u_bram_out (
//        .clka   (i_clk),
//        .ena    (1'b1),
//        .wea    (wr_en),
//        .addra  (wr_addr),
//        .dina   (wr_data),

//        .clkb   (i_clk),
//        .enb    (1'b1),
//        .web    (1'b0),
//        .addrb  (probe_addr),
//        .dinb   (16'b0),
//        .doutb  (o_probe_doutb)
//    );

//endmodule
