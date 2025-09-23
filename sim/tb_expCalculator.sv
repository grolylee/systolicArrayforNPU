// // // // // // `timescale 1ns / 1ps

// // // // // // module tb_expCalculator;

// // // // // //   // Parameters
// // // // // //   parameter BIT_WIDTH = 16;
// // // // // //   parameter FRAC_BITS = 12;
// // // // // //   parameter SCALE = 1 << FRAC_BITS;  // 4096

// // // // // //   // Signals
// // // // // //   logic clk;
// // // // // //   logic rst;
// // // // // //   logic valid_in;
// // // // // //   logic signed [BIT_WIDTH-1:0] in;
// // // // // //   logic signed [BIT_WIDTH-1:0] out;
// // // // // //   logic valid_out;

// // // // // //   // Instantiate DUT
// // // // // //   expCalculator dut (
// // // // // //       .i_clk  (clk),
// // // // // //       .i_rst  (rst),
// // // // // //       .i_valid(valid_in),
// // // // // //       .i_data (in),
// // // // // //       .o_exp  (out),
// // // // // //       .o_valid(valid_out)
// // // // // //   );

// // // // // //   // Clock generation
// // // // // //   initial begin
// // // // // //     clk = 0;
// // // // // //     forever #5 clk = ~clk;  // 100 MHz clock
// // // // // //   end

// // // // // //   // Stimulus
// // // // // //   initial begin
// // // // // //     // Reset
// // // // // //     rst = 1;
// // // // // //     valid_in = 0;
// // // // // //     in = 0;
// // // // // //     #20;
// // // // // //     rst = 0;
// // // // // //     #10;

// // // // // //     // Test case 1: x = -2 (in = -8192), expected exp(-2) ≈ 0.1353 * 4096 ≈ 554 (16'h022a)
// // // // // //     valid_in = 1;
// // // // // //     in = -2 * SCALE;  // -8192
// // // // // //     #10;
// // // // // //     valid_in = 0;
// // // // // //     #30;  // Wait for pipeline (2 cycles + margin)

// // // // // //     // Test case 2: x = -1 (in = -4096), expected exp(-1) ≈ 0.3679 * 4096 ≈ 1507 (16'h05e3)
// // // // // //     valid_in = 1;
// // // // // //     in = -1 * SCALE;  // -4096
// // // // // //     #10;
// // // // // //     valid_in = 0;
// // // // // //     #30;

// // // // // //     // Test case 3: x = -8 (in = -32768), expected ≈ 0 (clamp)
// // // // // //     valid_in = 1;
// // // // // //     in = -8 * SCALE;  // -32768
// // // // // //     #10;
// // // // // //     valid_in = 0;
// // // // // //     #30;

// // // // // //     // Test case 4: x = 0 (in = 0), expected ≈ 1 * 4096 = 4096 (16'h1000), nhưng clamp to LUT max ≈ 3615 (exp(-0.125) ≈ 0.8825 * 4096)
// // // // // //     valid_in = 1;
// // // // // //     in = 0;
// // // // // //     #10;
// // // // // //     valid_in = 0;
// // // // // //     #30;

// // // // // //     // Test case 5: x = -0.5 (in = -2048), expected exp(-0.5) ≈ 0.6065 * 4096 ≈ 2483 (16'h09b3 approx)
// // // // // //     valid_in = 1;
// // // // // //     in = -2048;
// // // // // //     #10;
// // // // // //     valid_in = 0;
// // // // // //     #30;

// // // // // //     // Finish simulation
// // // // // //     #50;
// // // // // //     $display("Simulation finished.");
// // // // // //     $finish;
// // // // // //   end

// // // // // //   // Monitor outputs
// // // // // //   initial begin
// // // // // //     $monitor("Time=%0t | valid_out=%b | in=%d (real=%f) | out=%d (real=%f)", $time, valid_out, in,
// // // // // //              $itor(in) / SCALE, out, $itor(out) / SCALE);
// // // // // //   end

// // // // // //   // Dump waves for ModelSim
// // // // // //   initial begin
// // // // // //     $dumpfile("tb_expCalculator.vcd");
// // // // // //     $dumpvars(0, tb_expCalculator);
// // // // // //   end

// // // // // // endmodule
// // // // // `timescale 1ns / 1ps

// // // // // module tb_expCalculator;

// // // // //     // Parameters
// // // // //     parameter BIT_WIDTH = 16;
// // // // //     parameter FRAC_BITS = 12;
// // // // //     parameter SCALE = 4096;  // 4096

// // // // //     // Signals
// // // // //     logic clk;
// // // // //     logic rst;
// // // // //     logic valid_in;
// // // // //     logic signed [BIT_WIDTH-1:0] in;
// // // // //     logic signed [BIT_WIDTH-1:0] out;
// // // // //     logic valid_out;

// // // // //     // Instantiate DUT
// // // // //     expCalculator dut (
// // // // //         .clk(clk),
// // // // //         .rst(rst),
// // // // //         .valid_in(valid_in),
// // // // //         .in(in),
// // // // //         .out(out),
// // // // //         .valid_out(valid_out)
// // // // //     );

// // // // //     // Clock generation
// // // // //     initial begin
// // // // //         clk = 0;
// // // // //         forever #5 clk = ~clk;  // 100 MHz clock
// // // // //     end

// // // // //     // Stimulus
// // // // //     initial begin
// // // // //         // Reset
// // // // //         rst = 1;
// // // // //         valid_in = 0;
// // // // //         in = 0;
// // // // //         #20;
// // // // //         rst = 0;
// // // // //         #10;

// // // // //         // Test cases
// // // // //         // x = -2
// // // // //         valid_in = 1;
// // // // //         in = -8192;  // -8192
// // // // //         #10;
// // // // //         valid_in = 0;
// // // // //         #50;  // Wait longer for pipeline

// // // // //         // x = -1
// // // // //         valid_in = 1;
// // // // //         in = -4096;  // -4096
// // // // //         #10;
// // // // //         valid_in = 0;
// // // // //         #50;

// // // // //         // x = -8
// // // // //         valid_in = 1;
// // // // //         in = -32768;  // -32768
// // // // //         #10;
// // // // //         valid_in = 0;
// // // // //         #50;

// // // // //         // x = 0
// // // // //         valid_in = 1;
// // // // //         in = 0;
// // // // //         #10;
// // // // //         valid_in = 0;
// // // // //         #50;

// // // // //         // x = -0.5
// // // // //         valid_in = 1;
// // // // //         in = -2048;
// // // // //         #10;
// // // // //         valid_in = 0;
// // // // //         #50;

// // // // //         // Finish
// // // // //         #50;
// // // // //         $display("Simulation finished.");
// // // // //         $finish;
// // // // //     end

// // // // //     // Monitor
// // // // //     initial begin
// // // // //         $monitor("Time=%0t | valid_out=%b | in=%d (real=%f) | out=%d (real=%f) | index=%d | delta_fixed=%d",
// // // // //                  $time, valid_out, in, $itor(in)/SCALE, out, $itor(out)/SCALE, dut.index, dut.delta_fixed);
// // // // //     end

// // // // //     // Dump waves
// // // // //     initial begin
// // // // //         $dumpfile("exp_calculator_tb.vcd");
// // // // //         $dumpvars(0, tb_expCalculator);
// // // // //     end

// // // // // endmodule

// // // // `timescale 1ns / 1ps

// // // // module tb_expCalculator;

// // // //     // Parameters
// // // //     parameter BIT_WIDTH = 16;
// // // //     parameter FRAC_BITS = 12;
// // // //     parameter SCALE = 1 << FRAC_BITS;  // 4096

// // // //     // Signals
// // // //     logic clk;
// // // //     logic rst;
// // // //     logic valid_in;
// // // //     logic signed [BIT_WIDTH-1:0] in;
// // // //     logic signed [BIT_WIDTH-1:0] out;
// // // //     logic valid_out;

// // // //     // Instantiate DUT
// // // //     expCalculator dut (
// // // //         .clk(clk),
// // // //         .rst(rst),
// // // //         .valid_in(valid_in),
// // // //         .in(in),
// // // //         .out(out),
// // // //         .valid_out(valid_out)
// // // //     );

// // // //     // Clock generation
// // // //     initial begin
// // // //         clk = 0;
// // // //         forever #5 clk = ~clk;  // 100 MHz clock
// // // //     end

// // // //     // Stimulus
// // // //     initial begin
// // // //         // Reset
// // // //         rst = 1;
// // // //         valid_in = 0;
// // // //         in = 0;
// // // //         #20;
// // // //         rst = 0;
// // // //         #10;

// // // //         // Test cases
// // // //         // x = -2
// // // //         valid_in = 1;
// // // //         in = -2 * SCALE;  // -8192
// // // //         #10;
// // // //         valid_in = 0;
// // // //         #70;  // Wait 3 cycles + margin

// // // //         // x = -1
// // // //         valid_in = 1;
// // // //         in = -1 * SCALE;  // -4096
// // // //         #10;
// // // //         valid_in = 0;
// // // //         #70;

// // // //         // x = -8
// // // //         valid_in = 1;
// // // //         in = -8 * SCALE;  // -32768
// // // //         #10;
// // // //         valid_in = 0;
// // // //         #70;

// // // //         // x = 0
// // // //         valid_in = 1;
// // // //         in = 0;
// // // //         #10;
// // // //         valid_in = 0;
// // // //         #70;

// // // //         // x = -0.5
// // // //         valid_in = 1;
// // // //         in = -2048;
// // // //         #10;
// // // //         valid_in = 0;
// // // //         #70;

// // // //         // Finish
// // // //         #50;
// // // //         $display("Simulation finished.");
// // // //         $finish;
// // // //     end

// // // //     // Monitor
// // // //     initial begin
// // // //         $monitor("Time=%0t | valid_out=%b | in=%d (real=%f) | out=%d (real=%f) | index=%d | delta_fixed=%d | exp_base=%d | slope=%d | product=%d",
// // // //                  $time, valid_out, in, $itor(in)/SCALE, out, $itor(out)/SCALE,
// // // //                  dut.index, dut.delta_fixed, dut.exp_base_reg, dut.slope_reg, dut.product);
// // // //     end

// // // //     // Dump waves
// // // //     initial begin
// // // //         $dumpfile("exp_calculator_tb.vcd");
// // // //         $dumpvars(0, tb_expCalculator);
// // // //     end

// // // // endmodule

// // // // `timescale 1ns / 1ps

// // // // module tb_expCalculator;

// // // //     // Parameters
// // // //     parameter BIT_WIDTH = 16;
// // // //     parameter FRAC_BITS = 12;
// // // //     parameter SCALE = 1 << FRAC_BITS;  // 4096

// // // //     // Signals
// // // //     logic clk;
// // // //     logic rst;
// // // //     logic valid_in;
// // // //     logic signed [BIT_WIDTH-1:0] in;
// // // //     logic signed [BIT_WIDTH-1:0] out;
// // // //     logic valid_out;

// // // //     // Instantiate DUT
// // // //     expCalculator dut (
// // // //         .clk(clk),
// // // //         .rst(rst),
// // // //         .valid_in(valid_in),
// // // //         .in(in),
// // // //         .out(out),
// // // //         .valid_out(valid_out)
// // // //     );

// // // //     // Clock generation
// // // //     initial begin
// // // //         clk = 0;
// // // //         forever #5 clk = ~clk;  // 100 MHz clock
// // // //     end

// // // //     // Stimulus
// // // //     initial begin
// // // //         // Reset
// // // //         rst = 1;
// // // //         valid_in = 0;
// // // //         in = 0;
// // // //         #20;
// // // //         rst = 0;
// // // //         #10;

// // // //         // Test case: x = -0.5
// // // //         valid_in = 1;
// // // //         in = -2048;  // -0.5 * 4096
// // // //         #10;
// // // //         valid_in = 0;
// // // //         #100;  // Wait 5 cycles + margin for pipeline

// // // //         // Finish
// // // //         #50;
// // // //         $display("Simulation finished.");
// // // //         $finish;
// // // //     end

// // // //     // Monitor
// // // //     initial begin
// // // //         $monitor("Time=%0t | valid_out=%b | in=%d (real=%f) | out=%d (real=%f) | index=%d | delta_fixed=%d | x0=%d | exp_base=%d | slope=%d | product=%d",
// // // //                  $time, valid_out, in, $itor(in)/SCALE, out, $itor(out)/SCALE,
// // // //                  dut.index, dut.delta_fixed, dut.x0, dut.exp_base_reg, dut.slope_reg, dut.product);
// // // //     end

// // // //     // Dump waves
// // // //     initial begin
// // // //         $dumpfile("exp_calculator_tb.vcd");
// // // //         $dumpvars(0, tb_expCalculator);
// // // //     end

// // // // endmodule

// // // `timescale 1ns / 1ps

// // // module tb_expCalculator;

// // //     // Parameters
// // //     parameter BIT_WIDTH = 16;
// // //     parameter FRAC_BITS = 12;
// // //     parameter SCALE = 1 << FRAC_BITS;  // 4096

// // //     // Signals
// // //     logic clk;
// // //     logic rst;
// // //     logic valid_in;
// // //     logic signed [BIT_WIDTH-1:0] in;
// // //     logic signed [BIT_WIDTH-1:0] out;
// // //     logic valid_out;

// // //     // Instantiate DUT
// // //     expCalculator dut (
// // //         .i_clk(clk),
// // //         .i_rst(rst),
// // //         .i_valid(valid_in),
// // //         .i_data(in),
// // //         .o_exp(out),
// // //         .o_valid(valid_out)
// // //     );

// // //     // Clock generation
// // //     initial begin
// // //         clk = 0;
// // //         forever #5 clk = ~clk;  // 100 MHz clock
// // //     end

// // //     // Stimulus
// // //     initial begin
// // //         // Reset
// // //         rst = 1;
// // //         valid_in = 0;
// // //         in = 0;
// // //         #20;
// // //         rst = 0;
// // //         #10;

// // //         // Test case: x = -0.5
// // //         valid_in = 1;
// // //         in = -2048;  // -0.5 * 4096
// // //         #10;
// // //         valid_in = 0;
// // //         #100;  // Wait 5 cycles + margin for pipeline

// // //         // Finish
// // //         #50;
// // //         $display("Simulation finished.");
// // //         $finish;
// // //     end

// // //     // Monitor
// // //     initial begin
// // //         $monitor("Time=%0t | valid_out=%b | in=%d (real=%f) | out=%d (real=%f) | index=%d | delta_fixed=%d",
// // //                  $time, valid_out, in, $itor(in)/SCALE, out, $itor(out)/SCALE,
// // //                  dut.index, dut.deltaFixed);
// // //     end

// // //     // Dump waves
// // //     initial begin
// // //         $dumpfile("exp_calculator_tb.vcd");
// // //         $dumpvars(0, tb_expCalculator);
// // //     end

// // // endmodule

// // module tb_expCalculator;
// //     localparam BIT_WIDTH = 16;
// //     localparam SCALE = 4096.0; // Q4.12 scaling factor
// //     logic i_clk, i_rst, i_valid;
// //     logic signed [BIT_WIDTH-1:0] i_data;
// //     logic signed [BIT_WIDTH-1:0] o_exp;
// //     logic o_valid;

// //     // Instantiate DUT
// //     expCalculator dut (
// //         .i_clk(i_clk),
// //         .i_rst(i_rst),
// //         .i_valid(i_valid),
// //         .i_data(i_data),
// //         .o_exp(o_exp),
// //         .o_valid(o_valid)
// //     );

// //     // Clock generation
// //     initial begin
// //         i_clk = 0;
// //         forever #5 i_clk = ~i_clk; // 100 MHz clock
// //     end

// //     // Monitor
// //     initial begin
// //         $monitor("Time=%0t | o_valid=%b | i_data=%d (real=%f) | o_exp=%d (real=%f) | index=%d | deltaFixed=%d | dataReg=%d | expBaseReg=%d | slopeReg=%d | deltaFixedReg=%d | product=%d | validReg1=%b | validReg2=%b | validReg3=%b",
// //                  $time, o_valid, i_data, $itor(i_data)/SCALE, o_exp, $itor(o_exp)/SCALE,
// //                  dut.index, dut.deltaFixed, dut.dataReg, dut.expBaseReg, dut.slopeReg, dut.deltaFixedReg, dut.product, dut.validReg1, dut.validReg2, dut.validReg3);
// //     end

// //     // Test sequence
// //     initial begin
// //         // Reset
// //         i_rst = 1;
// //         i_valid = 0;
// //         i_data = 0;
// //         #20;
// //         i_rst = 0;
// //         #10;
// //         // Test multiple inputs
// //         i_valid = 1;
// //         i_data = 0; // x = -0.140137
// //         #10;
// //         i_data = -21627; // x = -1.0
// //         #10;
// //         i_data = -205; // x = -0.25
// //     #10;
// //         i_valid = 0;
// //         #30;
// //         $display("Simulation finished.");
// //         $finish;
// //     end
// // endmodule



// module tb_expCalculator;
//     localparam BIT_WIDTH = 16;
//     localparam SCALE     = 4096.0; // Q4.12 scaling factor

//     logic i_clk, i_rst, i_valid;
//     logic signed [BIT_WIDTH-1:0] i_data;
//     logic [BIT_WIDTH-1:0] o_exp;
//     logic o_valid;

//     // Instantiate DUT
//     expCalculator dut (
//         .i_clk(i_clk),
//         .i_rst(i_rst),
//         .i_valid(i_valid),
//         .i_data(i_data),
//         .o_exp(o_exp),
//         .o_valid(o_valid)
//     );

//     // Clock generation
//     initial begin
//         i_clk = 0;
//         forever #5 i_clk = ~i_clk; // 100 MHz
//     end

//     // Monitor pipeline signals
// initial begin
//     $monitor("t=%0t | i_valid=%b | i_data=%d (%.4f) | dataReg1=%d deltaFixed1=%d index1=%d v1=%b | expBase=%d slope=%d dataReg2=%d deltaFixed2=%d v2=%b | o_exp=%d (%.4f) v3=%b",
//              $time,
//              i_valid, i_data, $itor(i_data)/SCALE,
//              dut.dataReg1, dut.deltaFixed1, dut.index1, dut.validReg1,
//              dut.expBaseReg, dut.slopeReg, dut.dataReg2, dut.deltaFixed2, dut.validReg2,
//              o_exp, $itor(o_exp)/SCALE, dut.validReg3);
// end

//     // Stimulus
//     initial begin
//         // Reset
//         i_rst   = 1;
//         i_valid = 0;
//         i_data  = 0;
//         #20;
//         i_rst   = 0;
//         #10;

//         // Bơm nhiều input liên tục (pipeline streaming)
//         i_valid = 1;
//         i_data  = 16'sd0;        // 0.0
//   @(posedge i_clk);
//         i_data  = -16'sd3567;    // -1.0 (Q4.12)
//   @(posedge i_clk);
//         i_data  = -16'sd5080;     // -0.5
//   @(posedge i_clk);
//         i_data  = 16'sd0;    // -0.2
//     @(posedge i_clk);
//         i_data  = -16'sd4321;     // -0.01
//   @(posedge i_clk);
//         i_valid = 0;             // ngừng input

//         // Đợi thêm để xem output ra đều
//         #200;
//         $display("Simulation finished.");
//         $finish;
//     end
// endmodule



module tb_expCalculator;
    localparam BIT_WIDTH = 16;
    localparam SCALE     = 4096.0; // Q4.12 scaling factor

    logic i_clk, i_rst, i_valid;
    logic signed [BIT_WIDTH-1:0] i_data;
    logic signed [BIT_WIDTH-1:0] o_exp;
    logic o_valid;

    // Instantiate DUT
    expCalculator dut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_valid),
        .i_data(i_data),
        .o_exp(o_exp),
        .o_valid(o_valid)
    );

    // Clock generation: 100 MHz (10 ns period)
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end


    initial begin
        $monitor("t=%0t | i_valid=%b | i_data=%d (%.4f) | o_exp=%d (%.4f) ",
                 $time,
                 i_valid, i_data, $itor(i_data)/SCALE,
                 o_exp, $itor(o_exp)/SCALE);
    end

    // Stimulus
    localparam int N = 4;
    logic signed [BIT_WIDTH-1:0] stimulus [0:N-1];

    initial begin
        // Chuẩn bị mảng input (Q4.12)
        stimulus[0] = -16'sd28328;       // 0.0
        stimulus[1] = -16'sd3675;   // ~ -0.8701
        stimulus[2] = -16'sd2208;   // ~ -1.2388
        stimulus[3] = -16'sd18167;   // ~ -1.0540

        // Reset
        i_rst   = 1;
        i_valid = 0;
        i_data  = 0;
        #20;
        i_rst   = 0;
        #10;

        // Bơm mảng input liên tục
        i_valid = 1;
        for (int k = 0; k < N; k++) begin
            i_data = stimulus[k];
            @(posedge i_clk);
        end
        i_valid = 0;

        // Đợi thêm để xem hết pipeline output
        #200;
        $display("Simulation finished.");
        $finish;
    end
endmodule
