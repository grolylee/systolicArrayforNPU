`timescale 1ns/1ps

module tb_exp;

  parameter int BIT_WIDTH   = 16;
  parameter int FRAC_BITS   = 12;
  parameter int N_VECTORS   = 10000;   // số lượng input

  // Clock & reset
  logic clk;
  logic rst;

  // DUT I/O
  logic signed [BIT_WIDTH-1:0] i_data;
  logic                        i_valid;
  logic signed [BIT_WIDTH-1:0] o_data;
  logic                        o_valid;

  // File & stimulus
  logic signed [BIT_WIDTH-1:0] stimulus [0:N_VECTORS-1];
  integer fd_out;

  // Instance DUT
  expCalculator dut (
    .i_clk   (clk),
    .i_rst   (rst),
    .i_valid (i_valid),
    .i_data  (i_data),
    .o_valid (o_valid),
    .o_exp  (o_data)
  );

  // Clock gen
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100 MHz
  end

  // Reset
  initial begin
    rst = 1;
    i_valid = 0;
    #20 rst = 0;
  end

  // Load input từ stimulus.mem (hex signed Q4.12)
  initial begin
    $readmemh("stimulus.mem", stimulus);
  end

  // Ghi output ra file
  initial begin
    fd_out = $fopen("exp_outt.txt", "w");
    if (!fd_out) begin
      $display("Cannot open exp_out.txt");
      $finish;
    end
  end

  // Bơm input tuần tự vào DUT
  initial begin
    @(negedge rst);
    #10;

    for (int i = 0; i < N_VECTORS; i++) begin
      @(posedge clk);
      i_valid <= 1;
      i_data  <= stimulus[i];
    end

    // dừng valid
    @(posedge clk);
    i_valid <= 0;

    // chờ thêm vài chu kỳ cho output cuối cùng
    repeat (50) @(posedge clk);

    $fclose(fd_out);
    $finish;   // ✅ thoát hẳn, không treo prompt

  end


  // Ghi output mỗi khi o_valid
  always_ff @(posedge clk) begin
    if (o_valid) begin
      $fdisplay(fd_out, "%0d", o_data);  // ghi dạng signed decimal
    end
  end

endmodule



// `timescale 1ns/1ps

// module tb_exp;

//   parameter int BIT_WIDTH   = 16;
//   parameter int FRAC_BITS   = 12;
//   parameter int N_VECTORS   = 10000;   // file có 10k giá trị

//   // Clock & reset
//   logic clk;
//   logic rst;

//   // DUT I/O
//   logic signed [BIT_WIDTH-1:0] i_data;
//   logic                        i_valid;
//   logic signed [BIT_WIDTH-1:0] o_data;
//   logic                        o_valid;

//   // File & stimulus
//   logic signed [BIT_WIDTH-1:0] stimulus [0:N_VECTORS-1];
//   integer fd_out;

//   // Instance DUT
//   expCalculator dut (
//     .i_clk   (clk),
//     .i_rst   (rst),
//     .i_valid (i_valid),
//     .i_data  (i_data),
//     .o_valid (o_valid),
//     .o_exp   (o_data)
//   );

//   // Clock gen
//   initial begin
//     clk = 0;
//     forever #5 clk = ~clk;  // 100 MHz
//   end

//   // Reset
//   initial begin
//     rst = 1;
//     i_valid = 0;
//     #20 rst = 0;
//   end

//   // Load input từ stimulus.mem (hex signed Q4.12)
//   initial begin
//     $readmemh("stimulus.mem", stimulus);
//   end

//   // Ghi output ra file
//   initial begin
//     fd_out = $fopen("exp_outt.txt", "w");
//     if (!fd_out) begin
//       $display("Cannot open exp_outt.txt");
//       $finish;
//     end
//   end

//   // Bơm input: chỉ lấy 5 giá trị đầu
//   initial begin
//     @(negedge rst);
//     #10;

//     for (int i = 0; i < 5; i++) begin
//       @(posedge clk);
//       i_valid <= 1;
//       i_data  <= stimulus[i];
//       $display("t=%0t | Input[%0d] = %0d (real=%.5f)", 
//                $time, i, stimulus[i], stimulus[i] / 2.0**FRAC_BITS);
//     end

//     // dừng valid
//     @(posedge clk);
//     i_valid <= 0;

//     // chờ thêm vài chu kỳ cho output cuối cùng
//     repeat (50) @(posedge clk);

//     $fclose(fd_out);
//     $finish;   // ✅ kết thúc simulation
//   end

//   // Ghi output + in transcript
//   always_ff @(posedge clk) begin
//     if (o_valid) begin
//       $fdisplay(fd_out, "%0d", o_data);  // ghi file dạng signed decimal
//       $display("t=%0t | Output = %0d (real=%.5f)", 
//                $time, o_data, o_data / 2.0**FRAC_BITS);
//     end
//   end

// endmodule
