// // // `timescale 1ns / 1ps
// // // //module output_flatten (
// // // //    input  logic [31:0][31:0][15:0] matrix,
// // // //    output logic [15:0] flat_array [0:1023]
// // // //);
// // // //    genvar i, j;
// // // //    generate
// // // //        for (i = 0; i < 32; i++) begin : row
// // // //            for (j = 0; j < 32; j++) begin : col
// // // //                assign flat_array[(i << 5) + j] = matrix[i][j];
// // // //            end
// // // //        end
// // // //    endgenerate
// // // //endmodule

// // // module output_flatten (
// // //     input  logic                  i_clk,
// // //     input  logic                  i_rst,
// // //     input  logic                  i_valid,
// // //     input  logic signed [31:0][31:0][15:0] matrix,
// // //     output logic                  done,
// // //     output logic [9:0]           wr_addr,
// // //     output logic                 wr_en,
// // //     output logic [15:0]          wr_data
// // // );

// // //     logic [9:0] index;
// // //     logic [4:0] col;
// // //     logic [4:0] row;

// // //     assign row = index[9:5]; // index / 32
// // //     assign col = index[4:0]; // index % 32

// // //     always_ff @(posedge i_clk or posedge i_rst) begin
// // //         if (i_rst) begin
// // //             index   <= 0;
// // //             wr_en   <= 0;
// // //             done    <= 0;
// // //         end else if (i_valid && !done) begin
// // //             wr_en   <= 1;
// // //             wr_addr <= index;
// // //             wr_data <= matrix[row][col];

// // //             if (index == 10'd1023) begin
// // //                 done  <= 1;
// // //                 wr_en <= 0;
// // //             end else begin
// // //                 index <= index + 1;
// // //             end
// // //         end else begin
// // //             wr_en <= 0;
// // //         end
// // //     end

// // // endmodule




// // module output_flatten (
// //     input  logic                  i_clk,
// //     input  logic                  i_rst,
// //     input  logic                  i_valid,
// //     input  logic signed [31:0][31:0][15:0] matrix,
// //     output logic                  done,
// //     output logic [9:0]           wr_addr,
// //     output logic                 wr_en,
// //     output logic [15:0]          wr_data
// // );

// //     logic [9:0] index;
// //     logic [4:0] col;
// //     logic [4:0] row;
// //     logic       last_write;

// //     assign row = index[9:5]; // index / 32
// //     assign col = index[4:0]; // index % 32

// //     always_ff @(posedge i_clk or posedge i_rst) begin
// //         if (i_rst) begin
// //             index      <= 0;
// //             wr_en      <= 0;
// //             done       <= 0;
// //             last_write <= 0;
// //         end else if (i_valid && !done) begin
// //             if (index < 10'd1023) begin
// //                 wr_en      <= 1;
// //                 wr_addr    <= index;
// //                 wr_data    <= matrix[row][col];
// //                 index      <= index + 1;
// //                 last_write <= 0;
// //                 $display("Time %0t: Writing to BRAM, wr_addr = %0d, wr_data = %0h", $time, wr_addr, wr_data);
// //             end else if (index == 10'd1023) begin
// //                 wr_en      <= 1;
// //                 wr_addr    <= index;
// //                 wr_data    <= matrix[row][col];
// //                 index      <= index;
// //                 last_write <= 1;
// //                 $display("Time %0t: Writing last element to BRAM, wr_addr = %0d, wr_data = %0h", $time, wr_addr, wr_data);
// //             end else if (last_write) begin
// //                 wr_en      <= 0;
// //                 done       <= 1;
// //                 last_write <= 0;
// //                 $display("Time %0t: flatten_done asserted", $time);
// //             end
// //         end else begin
// //             wr_en <= 0;
// //         end
// //     end

// // endmodule


// module output_flatten #(
//     parameter int ROWS = 32,
//     parameter int COLS = 32,
//     parameter int BIT_WIDTH = 16,
//     parameter int ADDR_WIDTH = 10   // log2(32*32)
// )(
//     input  logic                  i_clk,
//     input  logic                  i_rst,

//     // Handshake input từ quantizer
//     input  logic                  i_valid,
//     input  logic [ROWS-1:0][COLS-1:0][BIT_WIDTH-1:0]  i_matrix ,
//     output logic                  o_ready,   // báo cho quantizer là flatten sẵn sàng nhận dữ liệu mới

//     // Handshake output báo hoàn tất
//     output logic                  o_done,

//     // BRAM write interface
//     output logic                  o_wr_en,
//     output logic [ADDR_WIDTH-1:0] o_wr_addr,
//     output logic [BIT_WIDTH-1:0]  o_wr_data
// );

//     // =========================================================
//     // FSM state
//     // =========================================================
//     typedef enum logic [1:0] {
//         S_IDLE,
//         S_WRITE,
//         S_DONE
//     } state_t;

//     state_t state, next_state;

//     // =========================================================
//     // Counters
//     // =========================================================
//     logic [ADDR_WIDTH-1:0] addr_cnt;
//     logic [5:0] row_cnt, col_cnt;

//     // Pipeline register cho data
//     logic [BIT_WIDTH-1:0] data_reg;

//     // =========================================================
//     // Next state logic
//     // =========================================================
//     always_comb begin
//         next_state = state;
//         unique case (state)
//             S_IDLE : if (i_valid) next_state = S_WRITE;
//             S_WRITE: if (addr_cnt == ROWS*COLS-1) next_state = S_DONE;
//             S_DONE : next_state = S_IDLE;
//         endcase
//     end

//     // =========================================================
//     // State update
//     // =========================================================
//     always_ff @(posedge i_clk or posedge i_rst) begin
//         if (i_rst) state <= S_IDLE;
//         else       state <= next_state;
//     end

//     // =========================================================
//     // Counter + pipeline
//     // =========================================================
//     always_ff @(posedge i_clk or posedge i_rst) begin
//         if (i_rst) begin
//             addr_cnt <= '0;
//             row_cnt  <= '0;
//             col_cnt  <= '0;
//             data_reg <= '0;
//         end else if (state == S_WRITE) begin
//             // pipeline 1 nhịp cho data
//             data_reg <= i_matrix[row_cnt][col_cnt];

//             if (col_cnt == COLS-1) begin
//                 col_cnt <= '0;
//                 row_cnt <= row_cnt + 1;
//             end else begin
//                 col_cnt <= col_cnt + 1;
//             end

//             addr_cnt <= addr_cnt + 1;
//         end else begin
//             addr_cnt <= '0;
//             row_cnt  <= '0;
//             col_cnt  <= '0;
//         end
//     end

//     // =========================================================
//     // Outputs
//     // =========================================================
//     assign o_wr_en   = (state == S_WRITE);
//     assign o_wr_addr = addr_cnt;
//     assign o_wr_data = data_reg;

//     assign o_ready   = (state == S_IDLE);
//     assign o_done    = (state == S_DONE);

//     // Debug
//     always_ff @(posedge i_clk) begin
//         if (o_wr_en) begin
//             $display("t=%0t | BRAM_out write: addr=%0d, data=%0h",
//                      $time, o_wr_addr, o_wr_data);
//         end
//         if (o_done) begin
//             $display("t=%0t | flatten_done asserted", $time);
//         end
//     end

// endmodule




module output_flatten #(
    parameter int ROWS = 32,
    parameter int COLS = 32,
    parameter int BIT_WIDTH = 16,
    parameter int ADDR_WIDTH = 10
)(
    input  logic                  i_clk,
    input  logic                  i_rst,

    // Handshake input
    input  logic                  i_valid,
    input  logic [ROWS-1:0][COLS-1:0][BIT_WIDTH-1:0] i_matrix,
    output logic                  o_ready,
    output logic                  o_done,

    // BRAM write interface
    output logic                  o_wr_en,
    output logic [ADDR_WIDTH-1:0] o_wr_addr,
    output logic [BIT_WIDTH-1:0]  o_wr_data
);

    localparam int TOTAL = ROWS*COLS;

    logic [ADDR_WIDTH:0] counter;   // đếm từ 0..TOTAL
    logic [BIT_WIDTH-1:0] data_reg;

    // FSM cực gọn
    typedef enum logic [1:0] {IDLE, WRITE, DONE} state_t;
    state_t state;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state    <= IDLE;
            counter  <= 0;
            data_reg <= 0;
        end else begin
            case (state)
                IDLE: if (i_valid) begin
                          state   <= WRITE;
                          counter <= 0;
                      end
                WRITE: begin
                          data_reg <= i_matrix[counter/COLS][counter%COLS];
                          counter  <= counter + 1;
                          if (counter == TOTAL-1)
                              state <= DONE;
                       end
                DONE: state <= IDLE;
            endcase
        end
    end

    assign o_wr_en   = (state == WRITE);
    assign o_wr_addr = counter;
    assign o_wr_data = data_reg;

    assign o_ready   = (state == IDLE);
    assign o_done    = (state == DONE);

endmodule