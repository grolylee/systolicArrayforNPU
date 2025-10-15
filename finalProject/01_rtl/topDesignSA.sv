// `timescale 1ns / 1ps
// //module topDesignSA(

//   //  input logic i_clk,
// //    input logic i_rst,
// //    input logic i_start,
// //    output logic [15:0] o_c_result [0:1023], // 32x32 = 1024 elements,
// //    output logic o_validResult
// //    );

// //    logic signed [31:0][31:0][7:0] i_a ;
// //    logic signed [31:0][31:0][7:0] i_b;
// //    logic signed [31:0][31:0][15:0] o_c;
// //    logic bramDone;

// //    top_bram_wrapper u_bram_fsm(
// //        .i_clk(i_clk),
// //        .i_rst(i_rst),
// //        .i_start(i_start),
// //        .o_matrixA(i_a),
// //        .o_matrixB(i_b),
// //        .o_done(bramDone)
// //        );

// //        systolicArray32x32_new u_sa32x32 (
// //            .i_clk(i_clk),
// //            .i_arst(i_rst),
// //            .i_validInput(bramDone),
// //            .i_a(i_a),
// //            .i_b(i_b),
// //            .o_c(o_c),
// //            .o_validResult(o_validResult)
// //            );

// //         output_flatten dut_flatten (
// ////         .i_clk(i_clk),
// //            .matrix(o_c),
// //            .flat_array(o_c_result)
// //         );

// //endmodule


// module topDesignSA(
//     input logic i_clk,
//     input logic i_rst,
//     input logic i_start,
//     output logic o_validResult
// );

//     logic signed [31:0][31:0][7:0] i_a;
//     logic signed [31:0][31:0][7:0] i_b;
//     logic signed [31:0][31:0][15:0] o_c;
//     logic bramDone;
    
//     logic        wr_en;
//     logic [9:0]  wr_addr;
//     logic [15:0] wr_data;

//     top_bram_wrapper u_bram_fsm(
//         .i_clk(i_clk),
//         .i_rst(i_rst),
//         .i_start(i_start),
//         .o_matrixA(i_a),
//         .o_matrixB(i_b),
//         .o_done(bramDone)
//     );

//     systolicArray32x32_new u_sa32x32 (
//         .i_clk(i_clk),
//         .i_arst(i_rst),
//         .i_validInput(bramDone),
//         .i_a(i_a),
//         .i_b(i_b),
//         .o_c(o_c),
//         .o_validResult(o_validResult)
//     );

//     output_flatten u_flatten (
//         .i_clk(i_clk),
//         .i_rst(i_rst),
//         .i_valid(o_validResult),
//         .matrix(o_c),
//         .done(), // optional
//         .wr_addr(wr_addr),
//         .wr_en(wr_en),
//         .wr_data(wr_data)
//     );

//     blk_mem_gen_out u_bram_out (
//         .clka(i_clk),
//         .ena(1'b1),
//         .wea(wr_en),
//         .addra(wr_addr),
//         .dina(wr_data),
//         .clkb(i_clk),
//         .enb(1'b1),
//         .web(1'b0),
//         .addrb(10'b0),
//         .dinb(16'b0),
//         .doutb()
//     );
// endmodule





`timescale 1ns / 1ps

module topDesignSA (
    input logic i_clk,
    input logic i_rst,  // Active-high reset
    input logic i_start,
    output logic o_validResult
);

    logic signed [31:0][31:0][7:0]  i_a;
    logic signed [31:0][31:0][7:0]  i_b;
    logic signed [31:0][31:0][31:0] o_c;  // Đổi thành 32-bit
    logic signed [31:0][31:0][15:0] o_cScaleClip;  // Đổi thành 32-bit

    logic bramDone;
    logic i_validScaleClip;
    logic o_validScaleClip;
    logic        wr_en;
    logic [9:0]  wr_addr;
    logic [15:0] wr_data;  // Đổi thành 32-bit

    top_bram_wrapper u_bram_fsm (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_start),
        .o_matrixA(i_a),
        .o_matrixB(i_b),
        .o_done(bramDone)
    );

    systolicArray32x32_new u_sa32x32 (
        .i_clk(i_clk),
        .i_arst(i_rst),
        .i_validInput(bramDone),
        .i_a(i_a),
        .i_b(i_b),
        .o_c(o_c),  // Kết nối với o_c 32-bit
        .o_validResult(i_validScaleClip)
    );

    // divine spare(d_k) with d_k = 64 (/8 = >>> 3) quantize clip Matrix to Q2.14 (input softmax) 

    quantizeScaleMatrix u_quantizeScaleMatrix (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_validScaleClip),
        .i_matrix(o_c),  // Nhận ma trận 32-bit
        .o_matrix(o_cScaleClip),  // Truyền tiếp ma trận 32-bit
        .o_valid(o_validScaleClip)
    );

    output_flatten u_flatten (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(o_validScaleClip),
        .matrix(o_cScaleClip),  // Nhận ma trận 32-bit
        .done(), // optional
        .wr_addr(wr_addr),
        .wr_en(wr_en),
        .wr_data(wr_data)  // Xuất wr_data 32-bit
    );

    blk_mem_gen_out u_bram_out (
        .clka(i_clk),
        .ena(1'b1),
        .wea(wr_en),
        .addra(wr_addr),
        .dina(wr_data),  // Nhận wr_data 32-bit
        .clkb(i_clk),
        .enb(1'b1),
        .web(1'b0),
        .addrb(10'b0),
        .dinb(16'b0),  // Đổi thành 32-bit
        .doutb()  // Đổi thành 32-bit (không sử dụng)
    );

    assign o_validResult = o_validScaleClip;

endmodule
