// `timescale 1ns / 1ps
// module systolicArray8x8 (
//     input  logic                           i_clk,
//     input  logic                           i_arst,  // Active-high reset
//     input  logic signed [7:0][7:0][7:0]    i_a,
//     input  logic signed [7:0][7:0][7:0]    i_b,
//     input  logic                           i_validInput,
//     output logic signed [7:0][7:0][31:0]   o_c, 
//     output logic                           o_validResult
// );

//   typedef enum logic [1:0] {
//     IDLE,
//     PHASE1,
//     PHASE2,
//     DONE
//   } state_t;
//   state_t state;

//   // Sub-blocks
//   logic signed [3:0][3:0][7:0] a0, a1, a2, a3;
//   logic signed [3:0][3:0][7:0] b0, b1, b2, b3;
//   logic signed [3:0][3:0][31:0] c00a, c00b, c01a, c01b, c10a, c10b, c11a, c11b;
//   logic signed [3:0][3:0][31:0] sa_out0, sa_out1, sa_out2, sa_out3;
//   logic validInputSA;
//   logic v0, v1, v2, v3;

//   // 4 systolicArray4x4 submodules
//   systolicArray4x4 u_SA0 (.i_clk, .i_arst, .i_a(a0), .i_b(b0),
//                           .i_validInput(validInputSA), .o_c(sa_out0), .o_validResult(v0));
//   systolicArray4x4 u_SA1 (.i_clk, .i_arst, .i_a(a1), .i_b(b1),
//                           .i_validInput(validInputSA), .o_c(sa_out1), .o_validResult(v1));
//   systolicArray4x4 u_SA2 (.i_clk, .i_arst, .i_a(a2), .i_b(b2),
//                           .i_validInput(validInputSA), .o_c(sa_out2), .o_validResult(v2));
//   systolicArray4x4 u_SA3 (.i_clk, .i_arst, .i_a(a3), .i_b(b3),
//                           .i_validInput(validInputSA), .o_c(sa_out3), .o_validResult(v3));

//   // FSM
//   always_ff @(posedge i_clk or posedge i_arst) begin
//     if (i_arst) begin
//       state <= IDLE;
//       validInputSA <= 0;
//       o_validResult <= 0;
//     end else begin
//       case (state)
//         IDLE: begin
//           o_validResult <= 0;
//           if (i_validInput) begin
//             load_phase1();
//             validInputSA <= 1;
//             state <= PHASE1;
//           end
//         end

//         PHASE1: begin
//           validInputSA <= 0;
//           if (v0 && v1 && v2 && v3) begin
//             c00a <= sa_out0;
//             c01a <= sa_out1;
//             c10a <= sa_out2;
//             c11a <= sa_out3;
//             load_phase2();
//             validInputSA <= 1;
//             state <= PHASE2;
//           end
//         end

//         PHASE2: begin
//           validInputSA <= 0;
//           if (v0 && v1 && v2 && v3) begin
//             c00b <= sa_out0;
//             c01b <= sa_out1;
//             c10b <= sa_out2;
//             c11b <= sa_out3;
//             state <= DONE;
//           end
//         end

//         DONE: begin
//           // Blocking assignment để cập nhật ngay
//           for (int i = 0; i < 4; i++) begin
//             for (int j = 0; j < 4; j++) begin
//               o_c[i][j]     = c00a[i][j] + c00b[i][j];
//               o_c[i][j+4]   = c01a[i][j] + c01b[i][j];
//               o_c[i+4][j]   = c10a[i][j] + c10b[i][j];
//               o_c[i+4][j+4] = c11a[i][j] + c11b[i][j];
//             end
//           end
//           o_validResult <= 1;   // giữ =1 1 cycle
//           state <= IDLE;
//         end

//         default: state <= IDLE;
//       endcase
//     end
//   end

//   // ---------------- Phase loaders ----------------
//   // Phase1: (A00·B00, A00·B01, A10·B00, A10·B01)
//   task load_phase1();
//     for (int i = 0; i < 4; i++) begin
//       for (int j = 0; j < 4; j++) begin
//         a0[i][j] = i_a[i][j];       // A00
//         b0[i][j] = i_b[i][j];       // B00

//         a1[i][j] = i_a[i][j];       // A00
//         b1[i][j] = i_b[i][j+4];     // B01

//         a2[i][j] = i_a[i+4][j];     // A10
//         b2[i][j] = i_b[i][j];       // B00

//         a3[i][j] = i_a[i+4][j];     // A10
//         b3[i][j] = i_b[i][j+4];     // B01
//       end
//     end
//   endtask

//   // Phase2: (A01·B10, A01·B11, A11·B10, A11·B11)
//   task load_phase2();
//     for (int i = 0; i < 4; i++) begin
//       for (int j = 0; j < 4; j++) begin
//         a0[i][j] = i_a[i][j+4];     // A01
//         b0[i][j] = i_b[i+4][j];     // B10

//         a1[i][j] = i_a[i][j+4];     // A01
//         b1[i][j] = i_b[i+4][j+4];   // B11

//         a2[i][j] = i_a[i+4][j+4];   // A11
//         b2[i][j] = i_b[i+4][j];     // B10

//         a3[i][j] = i_a[i+4][j+4];   // A11
//         b3[i][j] = i_b[i+4][j+4];   // B11
//       end
//     end
//   endtask

// endmodule



`timescale 1ns / 1ps
module systolicArray8x8 (
    input  logic                           i_clk,
    input  logic                           i_arst,  // Active-high reset
    input  logic signed [7:0][7:0][7:0]    i_a,
    input  logic signed [7:0][7:0][7:0]    i_b,
    input  logic                           i_validInput,
    output logic signed [7:0][7:0][31:0]   o_c, 
    output logic                           o_validResult
);

  typedef enum logic [1:0] {
    IDLE,
    PHASE1,
    PHASE2,
    DONE
  } state_t;
  state_t state;

  // Sub-blocks
  logic signed [3:0][3:0][7:0] a0, a1, a2, a3;
  logic signed [3:0][3:0][7:0] b0, b1, b2, b3;
  logic signed [3:0][3:0][31:0] c00a, c00b, c01a, c01b, c10a, c10b, c11a, c11b;
  logic signed [3:0][3:0][31:0] sa_out0, sa_out1, sa_out2, sa_out3;
  logic validInputSA;
  logic v0, v1, v2, v3;

  // 4 systolicArray4x4 submodules
  systolicArray4x4 u_SA0 (.i_clk, .i_arst, .i_a(a0), .i_b(b0),
                          .i_validInput(validInputSA), .o_c(sa_out0), .o_validResult(v0));
  systolicArray4x4 u_SA1 (.i_clk, .i_arst, .i_a(a1), .i_b(b1),
                          .i_validInput(validInputSA), .o_c(sa_out1), .o_validResult(v1));
  systolicArray4x4 u_SA2 (.i_clk, .i_arst, .i_a(a2), .i_b(b2),
                          .i_validInput(validInputSA), .o_c(sa_out2), .o_validResult(v2));
  systolicArray4x4 u_SA3 (.i_clk, .i_arst, .i_a(a3), .i_b(b3),
                          .i_validInput(validInputSA), .o_c(sa_out3), .o_validResult(v3));

  // FSM
  always_ff @(posedge i_clk or posedge i_arst) begin
    if (i_arst) begin
      state <= IDLE;
      validInputSA <= 0;
      o_validResult <= 0;
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
            load_phase2();
            validInputSA <= 1;
            state <= PHASE2;
          end
        end

        PHASE2: begin
          validInputSA <= 0;
          if (v0 && v1 && v2 && v3) begin
            c00b <= sa_out0;
            c01b <= sa_out1;
            c10b <= sa_out2;
            c11b <= sa_out3;
            state <= DONE;
          end
        end

        DONE: begin
          // Non-blocking để chốt kết quả, valid sẽ báo ở tick sau
          for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
              o_c[i][j]     <= c00a[i][j] + c00b[i][j];
              o_c[i][j+4]   <= c01a[i][j] + c01b[i][j];
              o_c[i+4][j]   <= c10a[i][j] + c10b[i][j];
              o_c[i+4][j+4] <= c11a[i][j] + c11b[i][j];
            end
          end
          o_validResult <= 1;   // báo valid 1 cycle sau khi o_c đã ổn định
          state <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

  // ---------------- Phase loaders ----------------
  task load_phase1();
    for (int i = 0; i < 4; i++) begin
      for (int j = 0; j < 4; j++) begin
        a0[i][j] = i_a[i][j];       // A00
        b0[i][j] = i_b[i][j];       // B00

        a1[i][j] = i_a[i][j];       // A00
        b1[i][j] = i_b[i][j+4];     // B01

        a2[i][j] = i_a[i+4][j];     // A10
        b2[i][j] = i_b[i][j];       // B00

        a3[i][j] = i_a[i+4][j];     // A10
        b3[i][j] = i_b[i][j+4];     // B01
      end
    end
  endtask

  task load_phase2();
    for (int i = 0; i < 4; i++) begin
      for (int j = 0; j < 4; j++) begin
        a0[i][j] = i_a[i][j+4];     // A01
        b0[i][j] = i_b[i+4][j];     // B10

        a1[i][j] = i_a[i][j+4];     // A01
        b1[i][j] = i_b[i+4][j+4];   // B11

        a2[i][j] = i_a[i+4][j+4];   // A11
        b2[i][j] = i_b[i+4][j];     // B10

        a3[i][j] = i_a[i+4][j+4];   // A11
        b3[i][j] = i_b[i+4][j+4];   // B11
      end
    end
  endtask

endmodule
