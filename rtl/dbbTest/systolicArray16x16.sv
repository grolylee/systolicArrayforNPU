`timescale 1ns/1ps
module systolicArray16x16 (
    input  logic                          i_clk,
    input  logic                          i_arst,       // Active-high reset
    input  logic                          i_validInput,
    input  logic signed [15:0][15:0][7:0] i_a,          // 16x16 input A
    input  logic signed [15:0][15:0][7:0] i_b,          // 16x16 input B
    output logic signed [15:0][15:0][31:0] o_c,         // 16x16 output C
    output logic                          o_validResult
);

  typedef enum logic [2:0] {
    IDLE,
    PHASE1,
    WAIT_PHASE1,
    PHASE2,
    WAIT_PHASE2,
    DONE
  } state_t;
  state_t state;

  // Sub-block inputs (8x8)
  logic signed [7:0][7:0][7:0] a0, a1, a2, a3;
  logic signed [7:0][7:0][7:0] b0, b1, b2, b3;

  // Outputs từ SA8x8
  logic signed [7:0][7:0][31:0] sa_out0, sa_out1, sa_out2, sa_out3;
  logic v0, v1, v2, v3;
  logic validInputSA;

  // Partial results
  logic signed [7:0][7:0][31:0] c00a, c01a, c10a, c11a;
  logic signed [7:0][7:0][31:0] c00b, c01b, c10b, c11b;

  // 4 systolicArray8x8 submodules
  systolicArray8x8 u_SA0 (.i_clk, .i_arst, .i_a(a0), .i_b(b0),
                          .i_validInput(validInputSA), .o_c(sa_out0), .o_validResult(v0));
  systolicArray8x8 u_SA1 (.i_clk, .i_arst, .i_a(a1), .i_b(b1),
                          .i_validInput(validInputSA), .o_c(sa_out1), .o_validResult(v1));
  systolicArray8x8 u_SA2 (.i_clk, .i_arst, .i_a(a2), .i_b(b2),
                          .i_validInput(validInputSA), .o_c(sa_out2), .o_validResult(v2));
  systolicArray8x8 u_SA3 (.i_clk, .i_arst, .i_a(a3), .i_b(b3),
                          .i_validInput(validInputSA), .o_c(sa_out3), .o_validResult(v3));

  // FSM
  always_ff @(posedge i_clk or posedge i_arst) begin
    if (i_arst) begin
      state <= IDLE;
      validInputSA <= 0;
      o_validResult <= 0;
      c00a <= '{default:0};
      c00b <= '{default:0};
      c01a <= '{default:0};
      c01b <= '{default:0};
      c10a <= '{default:0};
      c10b <= '{default:0};
      c11a <= '{default:0};
      c11b <= '{default:0};
      o_c <= '{default:0};
    end else begin
      case (state)
        IDLE: begin
          o_validResult <= 0;
          if (i_validInput) begin
            load_phase1();
            validInputSA <= 1;
            state <= PHASE1;
          end
        end

        PHASE1: begin
          validInputSA <= 0;
          if (v0 && v1 && v2 && v3) begin
            c00a <= sa_out0;
            c01a <= sa_out1;
            c10a <= sa_out2;
            c11a <= sa_out3;
            $display("Phase 1: c11a (A10·B01) =");
            for (int i = 0; i < 8; i++) begin
              for (int j = 0; j < 8; j++) begin
                $write("%6d ", sa_out3[i][j]);
              end
              $write("\n");
            end
            state <= WAIT_PHASE1;
          end
        end

        WAIT_PHASE1: begin
          load_phase2();
          validInputSA <= 1;
          state <= PHASE2;
        end

        PHASE2: begin
          validInputSA <= 0;
          if (v0 && v1 && v2 && v3) begin
            c00b <= sa_out0;
            c01b <= sa_out1;
            c10b <= sa_out2;
            c11b <= sa_out3;
            $display("Phase 2: c11b (A11·B11) =");
            for (int i = 0; i < 8; i++) begin
              for (int j = 0; j < 8; j++) begin
                $write("%6d ", sa_out3[i][j]);
              end
              $write("\n");
            end
            state <= WAIT_PHASE2;
          end
        end

        WAIT_PHASE2: begin
          state <= DONE;
        end

        DONE: begin
          $display("Before DONE assign: c11a =");
          for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
              $write("%6d ", c11a[i][j]);
            end
            $write("\n");
          end
          $display("Before DONE assign: c11b =");
          for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
              $write("%6d ", c11b[i][j]);
            end
            $write("\n");
          end
          for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
              o_c[i][j]     = c00a[i][j] + c00b[i][j];
              o_c[i][j+8]   = c01a[i][j] + c01b[i][j];
              o_c[i+8][j]   = c10a[i][j] + c10b[i][j];
              o_c[i+8][j+8] = c11a[i][j] + c11b[i][j];
            end
          end
          $display("DONE: o_c[8:15][8:15] =");
          for (int i = 8; i < 16; i++) begin
            for (int j = 8; j < 16; j++) begin
              $write("%6d ", o_c[i][j]);
            end
            $write("\n");
          end
          o_validResult <= 1;
          state <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

  // Kiểm tra đồng bộ tín hiệu valid
  always_ff @(posedge i_clk) begin
    if (state == PHASE1 && (v0 && v1 && v2 && v3)) begin
      if (v0 !== v1 || v1 !== v2 || v2 !== v3) begin
        $display("Lỗi: Tín hiệu valid không đồng bộ: v0=%b, v1=%b, v2=%b, v3=%b", v0, v1, v2, v3);
      end
    end
    if (state == PHASE2 && (v0 && v1 && v2 && v3)) begin
      if (v0 !== v1 || v1 !== v2 || v2 !== v3) begin
        $display("Lỗi: Tín hiệu valid không đồng bộ: v0=%b, v1=%b, v2=%b, v3=%b", v0, v1, v2, v3);
      end
    end
  end

  // Debug độ trễ tín hiệu valid
  always_ff @(posedge i_clk) begin
    if (v0 && !v1) $display("v0 asserted before v1 at time %t", $time);
    if (v1 && !v2) $display("v1 asserted before v2 at time %t", $time);
    if (v2 && !v3) $display("v2 asserted before v3 at time %t", $time);
    if (v3 && !v0) $display("v3 asserted before v0 at time %t", $time);
  end

  // Debug đầu vào của u_SA3
  task load_phase1();
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        a0[i][j] = i_a[i][j];
        b0[i][j] = i_b[i][j];
        a1[i][j] = i_a[i][j];
        b1[i][j] = i_b[i][j+8];
        a2[i][j] = i_a[i+8][j];
        b2[i][j] = i_b[i][j];
        a3[i][j] = i_a[i+8][j]; // a10
        b3[i][j] = i_b[i][j+8]; // b01
      end
    end
    $display("Phase 1 inputs for u_SA3: a3 =");
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        $write("%4d ", a3[i][j]);
      end
      $write("\n");
    end
    $display("Phase 1 inputs for u_SA3: b3 =");
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        $write("%4d ", b3[i][j]);
      end
      $write("\n");
    end
  endtask

  task load_phase2();
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        a0[i][j] = i_a[i][j+8];
        b0[i][j] = i_b[i+8][j];
        a1[i][j] = i_a[i][j+8];
        b1[i][j] = i_b[i+8][j+8];
        a2[i][j] = i_a[i+8][j+8];
        b2[i][j] = i_b[i+8][j];
        a3[i][j] = i_a[i+8][j+8];
        b3[i][j] = i_b[i+8][j+8];
      end
    end
    $display("Phase 2 inputs for u_SA3: a3 =");
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        $write("%4d ", a3[i][j]);
      end
      $write("\n");
    end
    $display("Phase 2 inputs for u_SA3: b3 =");
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        $write("%4d ", b3[i][j]);
      end
      $write("\n");
    end
  endtask

endmodule