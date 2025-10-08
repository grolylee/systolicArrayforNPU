`timescale 1ns / 1ps

module topdesignSytolic (
    input logic i_clk,
    input logic i_rst,  // Active-high reset
    input logic i_start,
    input logic signed [31:0][31:0][7:0]  i_a,
    input logic signed [31:0][31:0][7:0]  i_b,
    output logic signed [31:0][31:0][31:0] o_c,
    output logic o_validResult
);

logic o_validScaleClip;
logic i_validScaleClip;

logic signed [31:0][31:0][31:0] o_cScaleClip;
    systolicArray32x32_new u_sa32x32 (
        .i_clk(i_clk),
        .i_arst(i_rst),
        .i_validInput(i_start),
        .i_a(i_a),
        .i_b(i_b),
        .o_c(o_cScaleClip),
        .o_validResult(i_validScaleClip)
    );

    // divine spare(d_k) with d_k = 64 (/8 = >>> 3) quantize clip Matrix to Q2.14 (input softmax) 

    quantizeScaleMatrix u_quantizeScaleMatrix (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_validScaleClip),
        .i_matrix(o_cScaleClip),  // Nhận ma trận 32-bit
        .o_matrix(o_c),  // Truyền tiếp ma trận 32-bit
        .o_valid(o_validScaleClip)
    );

    assign o_validResult = o_validScaleClip;

endmodule
