// `timescale 1ns / 1ps
// module dsp_mult #(
//     parameter int BIT_WIDTH = 8
// ) (
//     input logic clk,
//     input logic rst_n,  // active-low reset
//     input logic signed [7:0] A,
//     input logic signed [7:0] B,
//     output logic signed [31:0] Product
// );

// // Q1.7 x Q1.7 = Q2.14

//   logic signed [7:0] A_reg, B_reg;
//   logic signed [31:0] Product_reg;

//   always_ff @(posedge clk, posedge rst_n) begin
//     if (rst_n) begin
//       A_reg <= '0;
//       B_reg <= '0;
//       Product_reg <= '0;
//     end else begin
//       A_reg <= A;
//       B_reg <= B;
//       if (A == 0 || B == 0) begin
//         Product_reg <= 31'sd0;
//       end else begin
//         Product_reg <= (A_reg * B_reg); // Q1.7 x Q1.7 = Q2.14 => 16-bit, product is 32-bit => Q18.14
//       end
//     end
//   end

//   assign Product = Product_reg;

// endmodule


`timescale 1ns / 1ps
module dsp_mult #(
    parameter int BIT_WIDTH = 8
) (
    input  logic clk,
    input  logic rst_n,  // active-low reset
    input  logic signed [BIT_WIDTH-1:0] A,
    input  logic signed [BIT_WIDTH-1:0] B,
    output logic signed [31:0] Product
);

    // Q1.7 x Q1.7 = Q2.14 (16-bit). Đưa vào thanh ghi pipeline 32-bit.
    logic signed [BIT_WIDTH-1:0] A_reg, B_reg;    // Stage 1
   (* use_dsp = "yes" *)    logic signed [31:0] mult_reg;                 // Stage 2

    // Stage 1: chốt input
    always_ff @(posedge clk, posedge rst_n) begin
        if (rst_n) begin
            A_reg <= '0;
            B_reg <= '0;
        end else begin
            A_reg <= A;
            B_reg <= B;
        end
    end

    // Stage 2: phép nhân
    always_ff @(posedge clk, posedge rst_n) begin
        if (rst_n) begin
            mult_reg <= '0;
        end else begin
            mult_reg <= A_reg * B_reg; // signed multiply
        end
    end

    // Stage 3: output (có thể giữ thêm 1 register nếu muốn delay ổn định)
    always_ff @(posedge clk, posedge rst_n) begin
        if (rst_n) begin
            Product <= '0;
        end else begin
            Product <= mult_reg;
        end
    end

endmodule
