// // `timescale 1ns/1ps

// // module tb_softmax32Elements;

// //   // Clock & reset
// //   logic i_clk, i_rst, i_start;
// //   logic o_validResult;

// //   // Instantiate DUT
// //   softmax32Elements dut (
// //     .i_clk(i_clk),
// //     .i_rst(i_rst),
// //     .i_start(i_start),
// //     .o_validResult(o_validResult)
// //   );

// //   // Clock 10ns
// //   initial begin
// //     i_clk = 0;
// //     forever #5 i_clk = ~i_clk;
// //   end

// //   // In input row (Q2.14)
// //   task print_input_row;
// //     $display("\n========== INPUT ROW (Q2.14) ==========");
// //     for (int i = 0; i < 32; i++) begin
// //       real val_real;
// //       val_real = dut.i_data[i] / 16384.0;
// //       $display("i_data[%0d] = %0d (%.6f)", i, dut.i_data[i], val_real);
// //     end
// //   endtask

// //   // In output vector (Q0.16) khi ghi BRAM
// //   task automatic print_output_vec_with_sum;
// //     real sum_real;
// //     sum_real = 0.0;
// //     $display("\n========== OUTPUT SOFTMAX VECTOR (Q0.16) ==========");
// //     for (int i = 0; i < 32; i++) begin
// //       real val_real;
// //       val_real = dut.o_softmax[i] / 65536.0;
// //       sum_real += val_real;
// //       $display("o_softmax[%0d] = %0d (%.6f)", i, dut.o_softmax[i], val_real);
// //     end
// //     $display("-------------------------------------------");
// //     $display("SUM (Q0.16) = %.6f", sum_real);
// //   endtask

// //   // Stimulus
// //   initial begin
// //     // Reset
// //     i_rst   = 1;
// //     i_start = 0;
// //     #20 i_rst = 0;

// //     // Start đọc BRAM
// //     @(posedge i_clk);
// //     i_start = 1;
// //     @(posedge i_clk);
// //     i_start = 0;

// //     // In input row khi BRAM done
// //     @(posedge dut.bramDone);
// //     print_input_row();

// //     // Chờ softmax hoàn tất
// //     @(posedge o_validResult);
// //     @(posedge i_clk);
// //     print_output_vec_with_sum();

// //     #50 $finish;
// //   end

// //   // Monitor ghi BRAM output
// //   always @(posedge i_clk) begin
// //     if (dut.wr_en) begin
// //       real val_real;
// //       val_real = dut.wr_data / 65536.0;
// //       $display("WRITE OUT: t=%0t | addr=%0d | data=%0d (%.6f)",
// //                $time, dut.wr_addr, dut.wr_data, val_real);
// //     end
// //   end

// // endmodule


// `timescale 1ns/1ps

// module tb_softmax32Elements;

//   // Clock & Reset
//   logic i_clk;
//   logic i_rst;
//   logic i_start;

//   // Kết nối tới DUT
//   logic o_done;

//   // Tín hiệu trung gian cho đọc BRAM
//   logic [4:0]  tb_rd_addr;
//   logic [15:0] tb_rd_data;

//   // Instance DUT
//   softmax32Elements dut (
//     .i_clk    (i_clk),
//     .i_rst    (i_rst),
//     .i_start  (i_start),
//     .o_done   (o_done)
//   );

//   // Nối testbench signal tới BRAM trong DUT
//   assign dut.u_bram_out.addrb = tb_rd_addr;
//   assign tb_rd_data           = dut.u_bram_out.doutb;

//   // Clock gen
//   initial begin
//     i_clk = 0;
//     forever #5 i_clk = ~i_clk; // 100MHz
//   end

// //  // Monitor để debug
// //  initial begin
// //    $monitor("Time=%0t: o_done=%b, bramDone=%b, o_validResult=%b, flatten_done=%b",
// //             $time, dut.o_done, dut.bramDone, dut.o_validResult, dut.flatten_done);
// //  end

//   // Task: in input row (Q2.14)
//   task print_input_row;
//     int i;
//     real val_real;
//     begin
//       $display("\n========== INPUT ROW (Q2.14) ==========");
//       for (i = 0; i < 32; i++) begin
//         val_real = dut.i_data[i] / 16384.0;
//         $display("i_data[%0d] = %0d (%.6f)", i, dut.i_data[i], val_real);
//       end
//     end
//   endtask
// task read_bram_outputs;
//   real sum_real, val_real;
//   int i;
//   begin
//     sum_real = 0.0;

//     // Đợi DUT báo ghi xong
//     @(posedge dut.o_done);
//     repeat (3) @(posedge i_clk);   // chờ thêm vài cycle an toàn

//     // Prefetch lần đầu
//     tb_rd_addr = 0;
//     @(posedge i_clk);

//     // Đọc toàn bộ (38 vòng như bạn viết, để pipeline dịch ra hết)
//     for (i = 0; i < 38; i++) begin
//       tb_rd_addr = i+1; // cấp địa chỉ tiếp theo
//       val_real   = tb_rd_data / 65536.0;
//       sum_real  += val_real;

//       // Bỏ qua 2 giá trị đầu, chỉ in từ i>=2
//       if (i >= 2 && i < 34) begin
//         $display("addr=%0d | data=%0d (%.6f)",
//                  i-2, tb_rd_data, val_real);
//       end

//       @(posedge i_clk);
//     end

//     $display("----------------------------------------------");
//     $display("SUM (Q0.16) = %.6f", sum_real);
//   end
// endtask



// //always @(posedge i_clk) begin
// //  $display("t=%0t | wr_en=%b | o_done=%b | wr_addr=%0d",
// //            $time, dut.wr_en, dut.o_done, dut.wr_addr);
// //end

// always @(posedge i_clk) begin
//     if (!dut.o_done) begin
//         tb_rd_addr <= 5'd0; // Giữ tb_rd_addr=0 khi chưa ghi xong
//     end
// end
// assign dut.u_bram_out.enb = dut.o_done ? 1'b1 : 1'b0;

//   // Stimulus
//   initial begin
//     // Init
//     i_rst   = 1;
//     i_start = 0;
//     tb_rd_addr = 0;
//     #20;
//     i_rst = 0;

//     // Start DUT
//     #20;
//     i_start = 1;
//     #10;
//     i_start = 0;

//     @(posedge dut.bramDone);

//     print_input_row();

//     // Đọc output từ BRAM
//     read_bram_outputs();
//     $finish;
//   end

// endmodule


`timescale 1ns/1ps

module tb_softmax32Elements;

  // Clock & Reset
  logic i_clk;
  logic i_rst;
  logic i_start;

  // Kết nối tới DUT
  logic o_done;

  // Tín hiệu trung gian cho đọc BRAM
  logic [4:0]  tb_rd_addr;
  logic [15:0] tb_rd_data;

  // Cycle counter (để đo latency)
  int tb_cycle_cnt;
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst)
      tb_cycle_cnt <= 0;
    else
      tb_cycle_cnt <= tb_cycle_cnt + 1;
  end

  // Instance DUT
  softmax32Elements dut (
    .i_clk    (i_clk),
    .i_rst    (i_rst),
    .i_start  (i_start),
    .o_done   (o_done)
  );

  // Nối testbench signal tới BRAM trong DUT
  assign dut.u_bram_out.addrb = tb_rd_addr;
  assign tb_rd_data           = dut.u_bram_out.doutb;

  // Clock gen
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk; // 100MHz
  end

  // Task: in input row (Q2.14)
  task print_input_row;
    int i;
    real val_real;
    begin
      $display("\n========== INPUT ROW (Q2.14) ==========");
      $display("[Cycle=%0d | Time=%0t] --- INPUT ROW START ---",
               tb_cycle_cnt, $time);
      for (i = 0; i < 32; i++) begin
        val_real = dut.i_data[i] / 16384.0;
        $display("[Cycle=%0d | Time=%0t] i_data[%0d] = %0d (%.6f)",
                 tb_cycle_cnt, $time, i, dut.i_data[i], val_real);
      end
      $display("[Cycle=%0d | Time=%0t] --- INPUT ROW END ---\n",
               tb_cycle_cnt, $time);
    end
  endtask

  // Task: đọc dữ liệu output từ BRAM
  task read_bram_outputs;
    real sum_real, val_real;
    int i;
    begin
      sum_real = 0.0;

      // Đợi DUT báo ghi xong
      @(posedge dut.o_done);
      repeat (3) @(posedge i_clk);   // chờ thêm vài cycle an toàn

      // Prefetch lần đầu
      tb_rd_addr = 0;
      @(posedge i_clk);

      // Đọc toàn bộ (38 vòng để pipeline dịch ra hết)
      for (i = 0; i < 38; i++) begin
        tb_rd_addr = i+1; // cấp địa chỉ tiếp theo
        val_real   = tb_rd_data / 65536.0;
        sum_real  += val_real;

        if (i >= 2 && i < 34) begin
          $display("[Cycle=%0d | Time=%0t] BRAM_OUT addr=%0d | data=%0d (%.6f)",
                   tb_cycle_cnt, $time, i-2, tb_rd_data, val_real);
        end

        @(posedge i_clk);
      end

      $display("----------------------------------------------");
      $display("[Cycle=%0d | Time=%0t] SUM (Q0.16) = %.6f",
               tb_cycle_cnt, $time, sum_real);
    end
  endtask

  // Giữ addr = 0 khi chưa ghi xong
  always @(posedge i_clk) begin
    if (!dut.o_done) begin
      tb_rd_addr <= 5'd0;
    end
  end
  assign dut.u_bram_out.enb = dut.o_done ? 1'b1 : 1'b0;

  // Stimulus
  initial begin
    // Init
    i_rst   = 1;
    i_start = 0;
    tb_rd_addr = 0;
    #20;
    i_rst = 0;

    // Start DUT
    #20;
    i_start = 1;
    #10;
    i_start = 0;

    @(posedge dut.bramDone);

    print_input_row();

    // Đọc output từ BRAM
    read_bram_outputs();

    // Tính latency end-to-end
    $display("==============================================");
    $display("End-to-End Latency (cycles) = %0d", tb_cycle_cnt);
    $display("==============================================");

    $finish;
  end
endmodule
