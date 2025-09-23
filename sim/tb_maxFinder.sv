

// // `timescale 1ns/1ns

// // module tb_maxFinder;

// //   localparam int BIT_WIDTH = 16;
// //   localparam int N         = 8;

// //   logic i_clk = 0;
// //   logic i_rst = 1;
// //   logic i_valid = 0;
// //   logic signed [BIT_WIDTH-1:0] i_data [N-1:0];
// //   logic signed [BIT_WIDTH-1:0] o_dataMax;
// //   logic o_valid;

// //   // DUT
// //   maxFinder #(
// //     .BIT_WIDTH(BIT_WIDTH),
// //     .N(N)
// //   ) dut (
// //     .i_clk(i_clk),
// //     .i_rst(i_rst),
// //     .i_valid(i_valid),
// //     .i_data(i_data),
// //     .o_dataMax(o_dataMax),
// //     .o_valid(o_valid)
// //   );

// //   // Clock 100 MHz
// //   always #5 i_clk = ~i_clk;

// //   // Stimulus
// //   initial begin
// //     $display("=== Simple tb_maxFinder start ===");
// //     $dumpfile("tb_maxFinder.vcd");
// //     $dumpvars(0, tb_maxFinder);

// //     // Reset
// //     repeat (3) @(posedge i_clk);
// //     i_rst <= 0;

// //     // Test 1: {1, 2, 3, 4}
// //     #10
// //     i_data <= '{16'sd4096, 16'sd8192, 16'sd12288, 16'sd16384, -8192, -4096, 0, -12288}; // Q4.12: 1.0,2.0,3.0,4.0
// //     i_valid <= 1;
// // #10

// //     // Test 2: {-2, -1, 0, -3}
// //     i_data <= '{-8192, -4096, 0, -12288, 20480, 28672, 24576, 8192}; // Q4.12: -2,-1,0,-3
// // #10

// //     // Test 3: {5, 7, 6, 2}
// //     i_data <= '{20480, 28672, 24576, 8192, -8192, -4096, 0, -12288}; // Q4.12: 5,7,6,2

// // #10
// //     i_valid <= 0;

// //     // Đợi vài chu kỳ để xem output
// //     repeat (10) @(posedge i_clk);

// //     $display("=== tb_maxFinder done ===");
// //     $finish;
// //   end

// //   // Monitor output
// //   always @(posedge i_clk) begin
// //     if (o_valid) begin
// //       $display("T=%0t | o_valid=1 | o_dataMax=%0d (Q4.12 real=%0.4f)",
// //         $time, o_dataMax, o_dataMax/4096.0);
// //     end
// //   end

// // endmodule

// `timescale 1ns/1ps

// module tb_maxFinder;

//     parameter int BIT_WIDTH = 16;
//     parameter int N = 8;

//     // DUT signals
//     logic                        i_clk;
//     logic                        i_rst;
//     logic                        i_valid;
//     logic                        i_ready;
//     logic                        o_ready;
//     logic                        o_valid;
//     logic                        o_row_done;
//     logic signed [N-1:0][BIT_WIDTH-1:0] i_data;
//     logic signed [BIT_WIDTH-1:0] o_dataMax;

//     // Instantiate DUT
//     maxFinder #(
//         .BIT_WIDTH(BIT_WIDTH),
//         .N(N)
//     ) dut (
//         .i_clk(i_clk),
//         .i_rst(i_rst),
//         .i_valid(i_valid),
//         .i_ready(i_ready),
//         .o_ready(o_ready),
//         .o_valid(o_valid),
//         .o_row_done(o_row_done),
//         .i_data(i_data),
//         .o_dataMax(o_dataMax)
//     );

//     // Clock
//     always #5 i_clk = ~i_clk;

//     // Data rows (cố định)
// logic signed [2:0][N-1:0][BIT_WIDTH-1:0] row_data = '{
//     '{ 10, 20, 15, -5, 0, -30, 40, 5 },     
//     '{ -100, -50, -20, -70, -90, -10, -30, -80 },
//     '{ 5, 100, 25, 88, 43, 77, 66, 22 }      
// };


//     // Main stimulus
//     initial begin
//         $display("=== TEST maxFinder ===");

//         // Init
//         i_clk = 0;
//         i_rst = 1;
//         i_valid = 0;
//         o_ready = 0;
//         i_data = '{default: 0};

//         #20;
//         i_rst = 0;

//         for (int row = 0; row < 3; row++) begin
//             wait (i_ready);
//             i_data = row_data[row];
//             i_valid = 1;
//             @(posedge i_clk);
//             i_valid = 0;

//             // Chờ xử lý và dữ liệu ra hợp lệ
//             wait (o_valid);
//             #2;
//             $display("[Row %0d] Max = %0d", row, o_dataMax);
//             o_ready = 1;
//             @(posedge i_clk);
//             o_ready = 0;
//         end

//         #20;
//         $display("=== FINISH TEST ===");
//         $finish;
//     end

// endmodule


`timescale 1ns/1ps

module tb_maxFinder;

    parameter int BIT_WIDTH = 16;
    parameter int N = 8;

    // DUT signals
    logic                        i_clk;
    logic                        i_rst;
    logic                        i_valid;
    logic                        o_valid;
    logic signed [BIT_WIDTH-1:0] i_data [N-1:0];
    logic signed [BIT_WIDTH-1:0] o_dataMax;

    // Instantiate DUT
    maxFinder #(
        .BIT_WIDTH(BIT_WIDTH),
        .N(N)
    ) dut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_valid),
        .i_data(i_data),
        .o_dataMax(o_dataMax),
        .o_valid(o_valid)
    );

    // Clock
    always #5 i_clk = ~i_clk;

    // Data rows (3 × 8 × 16-bit)
    logic signed [BIT_WIDTH-1:0] row_data [2][N-1:0]= '{
        '{ 10, 20, 15, -5, 0, -30, 40, 5 },
        '{ -100, -50, -20, -70, -90, -10, -30, -80 },
        '{ 5, 100, 25, 88, 43, 77, 66, 22 }
    };

    // Main stimulus
    initial begin
        $display("=== TEST maxFinder ===");

        i_clk = 0;
        i_rst = 1;
        i_valid = 0;
        i_data = '{default:0};

        #20 i_rst = 0;

        for (int row = 0; row < 3; row++) begin
            i_data  = row_data[row];
            i_valid = 1;
            @(posedge i_clk);
            i_valid = 0;

            wait (o_valid);
            #2;
        $write("Row %0d input = { ", row);
            for (int j = 0; j < N; j++) begin
                $write("%0d ", i_data[j]);
        end
        $write("} | Max = %0d\n", o_dataMax);
        #20;
        $display("=== FINISH TEST ===");
        $finish;
    end
    end
endmodule
