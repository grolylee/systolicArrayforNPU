// `timescale 1ns / 1ps

// module fsmBramReadRow #(
//     parameter int BIT_WIDTH   = 16,
//     parameter int N           = 32,
//     parameter int ADDR_WIDTH  = 5    // chỉ cần 5 bit cho 32 địa chỉ
// )(
//     input  logic                        clk,
//     input  logic                        rst,
//     input  logic                        start,            // bắt đầu đọc row
//     output logic [ADDR_WIDTH-1:0]       bram_addr,        // địa chỉ BRAM
//     input  logic signed [BIT_WIDTH-1:0] bram_dataA,       // data từ BRAM

//     output logic signed [BIT_WIDTH-1:0] o_data [N-1:0],   // vector 32 phần tử
//     // output logic                        o_valid,          // báo đã gom xong 1 row
//     output logic                        done              // báo hoàn tất
// );

//   // FSM states
//   typedef enum logic [1:0] {IDLE, READ, DONE_ST} state_t;
//   state_t state, next_state;

//   // Counter cột (0..31)
//   logic [ADDR_WIDTH-1:0] col_cnt;

//   // FSM state register
//   always_ff @(posedge clk or posedge rst) begin
//     if (rst) state <= IDLE;
//     else     state <= next_state;
//   end

//   // FSM next-state logic
//   always_comb begin
//     next_state = state;
//     case (state)
//       IDLE:    if (start)           next_state = READ;
//       READ:    if (col_cnt == N-1)  next_state = DONE_ST;
//       DONE_ST:                      next_state = IDLE;
//       default:                      next_state = IDLE;
//     endcase
//   end

//   // Counter cột
//   always_ff @(posedge clk or posedge rst) begin
//     if (rst) col_cnt <= 0;
//     else if (state == IDLE) col_cnt <= 0;
//     else if (state == READ) col_cnt <= col_cnt + 1;
//   end

//   // Địa chỉ BRAM xuất ra
//   assign bram_addr = col_cnt;

//   // Gom dữ liệu vào vector
//   always_ff @(posedge clk or posedge rst) begin
//     if (rst) begin
//       for (int j = 0; j < N; j++) o_data[j] <= '0;
//     end else if (state == READ) begin
//       o_data[col_cnt] <= bram_dataA;
//     end
//   end

//   // Khi đọc đủ 32 cột thì báo valid + done
//   // assign o_valid = (state == DONE_ST);
//   assign done    = (state == DONE_ST);

// endmodule

`timescale 1ns / 1ps

module fsmBramReadRow #(
    parameter int BIT_WIDTH   = 16,
    parameter int N           = 32,
    parameter int ADDR_WIDTH  = 5
)(
    input  logic                        clk,
    input  logic                        rst,
    input  logic                        start,
    output logic [ADDR_WIDTH-1:0]       bram_addr,
    input  logic signed [BIT_WIDTH-1:0] bram_dataA,
    output logic signed [BIT_WIDTH-1:0] o_data [N-1:0],
    output logic                        done
);

    // FSM states
    typedef enum logic [1:0] {IDLE, READ, DONE_ST} state_t;
    state_t state, next_state;

    // Counter cột (0..33 để bù pipeline)
    logic [ADDR_WIDTH:0] col_cnt; // Tăng kích thước lên 6 bit để chứa giá trị 33
    logic [ADDR_WIDTH-1:0] bram_addr_reg, bram_addr_reg2;

    // Phát hiện cạnh của start
    logic start_d, start_edge;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) start_d <= 0;
        else start_d <= start;
    end
    assign start_edge = start & ~start_d;

    // FSM state register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    // FSM next-state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE:    if (start_edge)      next_state = READ;
            READ:    if (col_cnt == N+1)  next_state = DONE_ST; // Chuyển trạng thái sau N+2 chu kỳ
            DONE_ST:                      next_state = IDLE;
            default:                      next_state = IDLE;
        endcase
    end

    // Counter cột
    always_ff @(posedge clk or posedge rst) begin
        if (rst) col_cnt <= 0;
        else if (state == IDLE) col_cnt <= 0;
        else if (state == READ) col_cnt <= col_cnt + 1;
    end

    // Pipeline địa chỉ BRAM
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bram_addr_reg <= 0;
            bram_addr_reg2 <= 0;
        end else if (state == READ) begin
            bram_addr_reg <= col_cnt[ADDR_WIDTH-1:0]; // Lấy 5 bit thấp
            bram_addr_reg2 <= bram_addr_reg;
        end
    end

    // Địa chỉ BRAM xuất ra
    assign bram_addr = col_cnt[ADDR_WIDTH-1:0]; // Lấy 5 bit thấp

    // Gom dữ liệu vào vector
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int j = 0; j < N; j++) o_data[j] <= '0;
        end else if (state == READ && col_cnt > 0) begin
            o_data[bram_addr_reg2] <= bram_dataA; // Sử dụng địa chỉ pipeline giai đoạn 2
        end
    end

    // Báo hoàn tất
    assign done = (state == DONE_ST);

endmodule