// // module tb_reciprocalUnsigned32;

// //     parameter IN_WIDTH = 32;
// //     parameter BIT_WIDTH = 16;
// //     parameter CLK_PERIOD = 10; // 100 MHz

// //     logic clk;
// //     logic rst;
// //     logic valid_in;
// //     logic [IN_WIDTH-1:0] i_sum; // Q6.26
// //     logic [BIT_WIDTH-1:0] o_reciprocal;
// //     logic o_valid;

// //     reciprocalNewtonCalcUnsigned #(
// //         .IN_WIDTH(IN_WIDTH),
// //         .BIT_WIDTH(BIT_WIDTH),
// //         .LUT_SIZE(256)
// //     ) dut (
// //         .i_clk(clk),
// //         .i_rst(rst),
// //         .i_valid(valid_in),
// //         .i_sum(i_sum),
// //         .o_reciprocal(o_reciprocal),
// //         .o_valid(o_valid)
// //     );

// //     initial begin
// //         clk = 0;
// //         forever #(CLK_PERIOD/2) clk = ~clk;
// //     end

// //     function real q28_to_real(input [IN_WIDTH-1:0] value);
// //         return $itor(value) / (1 << 26);
// //     endfunction

// //     function real q16_to_real(input [BIT_WIDTH-1:0] value);
// //         return $itor(value) / (1 << 16);
// //     endfunction

// //         initial begin
// //         // Reset
// //         valid_in = 0;
// //         i_sum    = 0;
// //         @(posedge clk);
// //         rst = 1;
// //         repeat (2) @(posedge clk);
// //         rst = 0;

// //         // Test case 1: i_sum = 2.666667
// //         @(posedge clk);
// //         valid_in = 1;
// //         i_sum    = 32'd1625376686;

// //         @(posedge clk);
// //         i_sum    = 32'd1231231232;

// //         @(posedge clk);
// //         valid_in = 0;   // ngừng truyền input

// //         // Đợi output hợp lệ
// //         wait (o_valid);
// //         @(posedge clk);

// //         $display("Simulation finished.");
// //         $finish;
// //     end

    
// //     always @(posedge clk) begin
// //         $display("Time=%0t | valid_in=%b | i_sum=%0d (real=%.6f) | o_reciprocal=0x%04x (real=%.6f) | o_valid=%b",
// //                  $time, valid_in, i_sum, q28_to_real(i_sum), o_reciprocal, q16_to_real(o_reciprocal), o_valid);
// //     end

// // endmodule



// module tb_reciprocalUnsigned32;
//     parameter IN_WIDTH = 32;
//     parameter BIT_WIDTH = 16;
//     parameter CLK_PERIOD = 10;

//     logic clk, rst, valid_in;
//     logic [IN_WIDTH-1:0] i_sum;
//     logic [BIT_WIDTH-1:0] o_reciprocal;
//     logic o_valid;

//     reciprocalNewtonCalcUnsigned dut (
//         .i_clk(clk),
//         .i_rst(rst),
//         .i_valid(valid_in),
//         .i_sum(i_sum),
//         .o_reciprocal(o_reciprocal),
//         .o_valid(o_valid)
//     );

//     // Clock
//     initial begin
//         clk = 0;
//         forever #(CLK_PERIOD/2) clk = ~clk;
//     end

//     // Convert helper
//     function real q26_to_real(input [IN_WIDTH-1:0] value);
//         return $itor(value) / (1 << 26);
//     endfunction
//     function real q16_to_real(input [BIT_WIDTH-1:0] value);
//         return $itor(value) / (1 << 16);
//     endfunction

//     // Stimulus
//     int num_inputs = 5;
//     int outputs_seen = 0;
//     int cycle = 0;
//     logic [IN_WIDTH-1:0] test_vec [0:4];

//     initial begin
//         // chuẩn bị 5 giá trị Q6.26 (1.0, 2.0, 4.0, 8.0, 16.0)
//         test_vec[0] = 32'd913457152;    // 1.0
//         test_vec[1] = 32'd138035200;   // 2.0
//         test_vec[2] = 32'd173916160;   // 4.0


//         // Reset
//         rst = 1; valid_in = 0; i_sum = 0;
//         repeat (3) @(posedge clk);
//         rst = 0;

//         // Bơm input liên tục mỗi chu kỳ
//         for (int i=0; i<num_inputs; i++) begin
//             @(posedge clk);
//             valid_in <= 1;
//             i_sum    <= test_vec[i];
//         end

//         // Ngừng input
//         @(posedge clk);
//         valid_in <= 0;
//         i_sum    <= 0;
//     end

//     // Monitor: in output khi hợp lệ
//     always @(posedge clk) begin
//         if (o_valid) begin
//             outputs_seen++;
//             $display("Cycle=%0d | Input #%0d | i_sum=%.6f | Reciprocal = %.6f",
//                      cycle, outputs_seen, q26_to_real(i_sum), q16_to_real(o_reciprocal));
//             if (outputs_seen == num_inputs) begin
//                 $display("Done %0d output, stop", num_inputs);
//                 $finish;
//             end
//         end
//         cycle++;
//     end

//     // Monitor toàn bộ trạng thái mỗi chu kỳ
// always @(posedge clk) begin
//     $display("t=%0t | valid_in=%b | i_sum=%0d (%.4f) | o_valid=%b | o_recip=%0d (%.6f)",
//              $time, valid_in,
//              i_sum, q26_to_real(i_sum),
//              o_valid, o_reciprocal, q16_to_real(o_reciprocal));
// end

// endmodule





`timescale 1ns/1ps

module tb_reciprocalUnsigned32;
    parameter IN_WIDTH  = 32;
    parameter BIT_WIDTH = 16;
    parameter CLK_PERIOD = 10;

    logic clk, rst, valid_in;
    logic [IN_WIDTH-1:0] i_sum;
    logic [BIT_WIDTH-1:0] o_reciprocal;
    logic o_valid;

    // DUT
    reciprocalNewtonCalcUnsigned dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_valid(valid_in),
        .i_sum(i_sum),
        .o_reciprocal(o_reciprocal),
        .o_valid(o_valid)
    );

    // Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // File handle
    int fin, fout;
    int num_inputs;
    logic [IN_WIDTH-1:0] mem_data [$]; // dynamic array để load dữ liệu

    // Convert helper (để debug)
    function real q26_to_real(input [IN_WIDTH-1:0] value);
        return $itor($signed(value)) / (1 << 26);
    endfunction
    function real q16_to_real(input [BIT_WIDTH-1:0] value);
        return $itor($signed(value)) / (1 << 16);
    endfunction

    // Reset
    initial begin
        rst = 1; valid_in = 0; i_sum = 0;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Load input file
    initial begin
        // đọc toàn bộ input.mem (hex) vào mem_data
        $readmemh("input_reciprocal.mem", mem_data);
        num_inputs = mem_data.size();

        fout = $fopen("reciprocal_output_1loop.txt", "w");
        if (fout == 0) begin
            $display("Cannot open output.txt");
            $finish;
        end

        // Đợi reset xong
        @(negedge rst);

        // Bơm input
        for (int i = 0; i < num_inputs; i++) begin
            @(posedge clk);
            valid_in <= 1;
            i_sum    <= mem_data[i];
        end

        // Ngừng input
        @(posedge clk);
        valid_in <= 0;
        i_sum    <= 0;
    end

    // Ghi output khi o_valid
    always @(posedge clk) begin
        if (o_valid) begin
            $fwrite(fout, "%0d\n", $signed(o_reciprocal));
            // debug in console
            $display("Out: %0d (%.6f)", $signed(o_reciprocal), q16_to_real(o_reciprocal));
        end
    end

    // Stop simulation khi xử lý hết
    initial begin
        wait(!rst);
        // giả sử latency ~ 50 cycles sau cuối input
        #(num_inputs*CLK_PERIOD + 500*CLK_PERIOD);
        $display("Simulation timeout, finishing...");
        $finish;
    end
endmodule
