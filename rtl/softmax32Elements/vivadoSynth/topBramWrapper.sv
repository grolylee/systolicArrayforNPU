`timescale 1ns / 1ps

module topBramWrapper (
    input  logic i_clk,
    input  logic i_rst,
    input  logic i_start,
    output logic signed [15:0] o_row [31:0],  // chỉ 1 row (32 giá trị)
    output logic o_done
);

  // Địa chỉ BRAM (0..31)
  logic [4:0] bram_addr;
  logic signed [15:0] bram_dataA;
  logic o_valid;

  // BRAM 32x16 (init từ file .coe bạn đã chuẩn bị)
  blk_mem_gen_row u_bram (
      .clka (i_clk),
      .ena  (1'b1),
      .wea  (1'b0),
      .addra(bram_addr),
      .dina ('0),
      .douta(bram_dataA)
  );

  // FSM đọc 1 row 32 giá trị
  fsmBramReadRow u_fsm (
      .clk      (i_clk),
      .rst      (i_rst),
      .start    (i_start),
      .bram_addr(bram_addr),
      .bram_dataA(bram_dataA),
      .o_data   (o_row),
      .o_valid  (o_valid),
      .done     (o_done)
  );

endmodule
