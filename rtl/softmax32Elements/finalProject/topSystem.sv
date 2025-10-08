
// // endmodule
// `timescale 1ns/1ps
// // `default_nettype none

// module topSystem #(
//     parameter MATRIX_SIZE = 32,
//     parameter BIT_WIDTH   = 16,
//     parameter READ_LAT    = 3   // 👈 chỉnh theo latency thực tế của blk_mem_gen
// ) (
//     input  logic                           i_clk,      // Clock input
//     input  logic                           i_rst,      // Reset input
//     input  logic                           i_start,    // Start signal
//     output logic                           o_valid     // Valid signal for softmax output
// );


//  logic       [BIT_WIDTH-1:0]     o_softmax [31:0]; // Softmax output (UNSIGNED Q0.16)

//     // =========================================================
//     // Internal signals
//     // =========================================================
//     logic                    bramDone;
//     logic signed [31:0][31:0][7:0]   i_a;  // Matrix A
//     logic signed [31:0][31:0][7:0]   i_b;  // Matrix B
//     logic signed [31:0][31:0][31:0]  o_c;  // SA result (32-bit signed)

//     logic                    i_validScaleClip;
//     logic signed [31:0][31:0][15:0]  o_cScaleClip;
//     logic                    o_validScaleClip;

//     logic                    flatten_done;
//     logic [9:0]              wr_addr;
//     logic                    wr_en;
//     logic signed [BIT_WIDTH-1:0]    wr_data;

//     logic [9:0]              rd_addr;
//     logic signed [BIT_WIDTH-1:0]    rd_data;
//     logic                    rd_en;

//     logic                    softmax_start;
//     logic signed [BIT_WIDTH-1:0]    softmax_input [31:0];
//     logic                    softmax_valid;

//     // =========================================================
//     // Block: BRAM FSM
//     // =========================================================
//     top_bram_wrapper u_bram_fsm (
//         .i_clk(i_clk),
//         .i_rst(i_rst),
//         .i_start(i_start),
//         .o_matrixA(i_a),
//         .o_matrixB(i_b),
//         .o_done(bramDone)
//     );

//     // =========================================================
//     // Block: Systolic Array
//     // =========================================================
//     systolicArray32x32_new u_sa32x32 (
//         .i_clk(i_clk),
//         .i_arst(i_rst),
//         .i_validInput(bramDone),
//         .i_a(i_a),
//         .i_b(i_b),
//         .o_c(o_c),
//         .o_validResult(i_validScaleClip)
//     );

//     // =========================================================
//     // Block: Quantizer
//     // =========================================================
//     quantizeScaleMatrixToQ2_14 u_quantizeScaleMatrix (
//         .i_clk(i_clk),
//         .i_rst(i_rst),
//         .i_valid(i_validScaleClip),
//         .i_matrix(o_c),
//         .o_matrix(o_cScaleClip),
//         .o_valid(o_validScaleClip)
//     );

//     // =========================================================
//     // Block: Flatten
//     // =========================================================
//     output_flatten u_flatten (
//         .i_clk    (i_clk),
//         .i_rst    (i_rst),
//         .i_valid  (o_validScaleClip),
//         .i_matrix (o_cScaleClip),
//         .o_ready  (),
//         .o_done   (flatten_done),
//         .o_wr_en  (wr_en),
//         .o_wr_addr(wr_addr),
//         .o_wr_data(wr_data)
//     );

//     // =========================================================
//     // Block: Output BRAM
//     // =========================================================
//     blk_mem_gen_out u_bram_out (
//         .clka(i_clk),
//         .ena(1'b1),
//         .wea(wr_en),
//         .addra(wr_addr),
//         .dina(wr_data),
//         .clkb(i_clk),
//         .enb(rd_en),
//         .addrb(rd_addr),
//         .doutb(rd_data)
//     );

//     // =========================================================
//     // FSM đọc BRAM để feed vào Softmax
//     // =========================================================
//     typedef enum logic [1:0] {RD_IDLE, RD_READ, RD_DONE} rd_state_t;
//     rd_state_t rd_state;

//     logic [9:0] rd_counter;
//     logic [1:0] softmax_start_cnt;

//     always_ff @(posedge i_clk or posedge i_rst) begin
//         if (i_rst) begin
//             rd_state          <= RD_IDLE;
//             rd_counter        <= '0;
//             rd_addr           <= '0;
//             rd_en             <= 1'b0;
//             softmax_input     <= '{default:'0};
//             softmax_start     <= 1'b0;
//             softmax_start_cnt <= '0;
//         end else begin
//             case (rd_state)

//                 RD_IDLE: begin
//                     rd_en      <= 1'b0;
//                     rd_addr    <= '0;
//                     rd_counter <= '0;
//                     softmax_start <= 1'b0;
//                     if (flatten_done) begin
//                         rd_state <= RD_READ;
//                         rd_en    <= 1'b1;
//                         rd_addr  <= '0;
//                     end
//                 end

//                 RD_READ: begin
//                     rd_addr    <= rd_addr + 1;
//                     rd_counter <= rd_counter + 1;

//                     if (rd_counter >= READ_LAT) begin
//                         automatic int idx = rd_counter - READ_LAT;
//                         if (idx < MATRIX_SIZE) begin
//                             softmax_input[idx] <= rd_data;
//                             $display("t=%0t | rd_addr=%0d | softmax_input[%0d] = %0d",
//                                      $time, rd_addr, idx, $signed(rd_data));
//                         end
//                     end

//                     if (rd_counter == MATRIX_SIZE + READ_LAT) begin
//                         rd_en    <= 1'b0;
//                         rd_state <= RD_DONE;
//                         softmax_start_cnt <= 0;
//                     end
//                 end

//                 RD_DONE: begin
//                     if (softmax_start_cnt < 2) begin
//                         softmax_start     <= 1'b1;
//                         softmax_start_cnt <= softmax_start_cnt + 1;
//                     end else begin
//                         softmax_start <= 1'b0;
//                     end
//                 end

//                 default: begin
//                     rd_state      <= RD_IDLE;
//                     rd_en         <= 1'b0;
//                     rd_addr       <= '0;
//                     rd_counter    <= '0;
//                     softmax_start <= 1'b0;
//                 end

//             endcase
//         end
//     end

//     // =========================================================
//     // Block: Softmax
//     // =========================================================
//     bugSoftmax32 #(
//         .N(MATRIX_SIZE),
//         .BIT_WIDTH(BIT_WIDTH)
//     ) u_softmax32 (
//         .i_clk(i_clk),
//         .i_rst(i_rst),
//         .i_valid(softmax_start),
//         .i_data(softmax_input),
//         .o_data(o_softmax),       // UNSIGNED output
//         .o_valid(softmax_valid)
//     );

//     // =========================================================
//     // Assign output
//     // =========================================================
//     assign o_valid = softmax_valid;

// endmodule



`timescale 1ns/1ps

module topSystem #(
    parameter MATRIX_SIZE = 32,
    parameter BIT_WIDTH   = 16,
    parameter READ_LAT    = 3   // chỉnh theo latency thực tế của blk_mem_gen_out
) (
    input  logic        i_clk,      // Clock input
    input  logic        i_rst,      // Reset input
    input  logic        i_start,    // Start signal
    output logic        o_valid,    // báo softmax_done

    // Probe port để testbench đọc BRAM softmax
    input  logic [4:0]  i_probe_addr,
    output logic [15:0] o_probe_doutb
);

    // =========================================================
    // Internal signals
    // =========================================================
    logic                    bramDone;
    logic signed [31:0][31:0][7:0]   i_a;  // Matrix A
    logic signed [31:0][31:0][7:0]   i_b;  // Matrix B
    logic signed [31:0][31:0][31:0]  o_c;  // SA result (32-bit signed)

    logic                    i_validScaleClip;
    logic signed [31:0][31:0][15:0]  o_cScaleClip;
    logic                    o_validScaleClip;

    logic                    flatten_done;
    logic [9:0]              wr_addr;
    logic                    wr_en;
    logic signed [BIT_WIDTH-1:0]    wr_data;

    logic [9:0]              rd_addr;
    logic signed [BIT_WIDTH-1:0]    rd_data;
    logic                    rd_en;

    logic                    softmax_start;
    logic signed [BIT_WIDTH-1:0]    softmax_input [31:0];
    logic                    softmax_valid;

    logic [BIT_WIDTH-1:0]    o_softmax [31:0]; // Softmax output (UNSIGNED Q0.16)

    // Flatten softmax → BRAM
    logic [4:0]              wr_addr_output;
    logic                    wr_en_output;
    logic [15:0]             wr_data_output;
    logic                    softmax_done;

    // Probe BRAM signals
    logic                    probe_enb;
    logic [4:0]              probe_addrb;
    logic [15:0]             probe_doutb;

    assign o_probe_doutb = probe_doutb;

    // =========================================================
    // Block: BRAM FSM
    // =========================================================
    top_bram_wrapper u_bram_fsm (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i_start),
        .o_matrixA(i_a),
        .o_matrixB(i_b),
        .o_done(bramDone)
    );

    // =========================================================
    // Block: Systolic Array
    // =========================================================
    systolicArray32x32_new u_sa32x32 (
        .i_clk(i_clk),
        .i_arst(i_rst),
        .i_validInput(bramDone),
        .i_a(i_a),
        .i_b(i_b),
        .o_c(o_c),
        .o_validResult(i_validScaleClip)
    );

    // =========================================================
    // Block: Quantizer
    // =========================================================
    quantizeScaleMatrixToQ2_14 u_quantizeScaleMatrix (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_validScaleClip),
        .i_matrix(o_c),
        .o_matrix(o_cScaleClip),
        .o_valid(o_validScaleClip)
    );

    // =========================================================
    // Block: Flatten (matrix C -> BRAM_out)
    // =========================================================
    output_flatten u_flatten (
        .i_clk    (i_clk),
        .i_rst    (i_rst),
        .i_valid  (o_validScaleClip),
        .i_matrix (o_cScaleClip),
        .o_ready  (),
        .o_done   (flatten_done),
        .o_wr_en  (wr_en),
        .o_wr_addr(wr_addr),
        .o_wr_data(wr_data)
    );

    // =========================================================
    // Block: Output BRAM (matrix C sau quantizer)
    // =========================================================
    blk_mem_gen_out u_bram_out (
        .clka(i_clk),
        .ena(1'b1),
        .wea(wr_en),
        .addra(wr_addr),
        .dina(wr_data),
        .clkb(i_clk),
        .enb(rd_en),
        .addrb(rd_addr),
        .doutb(rd_data)
    );

    // =========================================================
    // FSM đọc BRAM để feed vào Softmax
    // =========================================================
    typedef enum logic [1:0] {RD_IDLE, RD_READ, RD_DONE} rd_state_t;
    rd_state_t rd_state;

    logic [9:0] rd_counter;
    logic [1:0] softmax_start_cnt;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            rd_state          <= RD_IDLE;
            rd_counter        <= '0;
            rd_addr           <= '0;
            rd_en             <= 1'b0;
            softmax_input     <= '{default:'0};
            softmax_start     <= 1'b0;
            softmax_start_cnt <= '0;
        end else begin
            case (rd_state)

                RD_IDLE: begin
                    rd_en      <= 1'b0;
                    rd_addr    <= '0;
                    rd_counter <= '0;
                    softmax_start <= 1'b0;
                    if (flatten_done) begin
                        rd_state <= RD_READ;
                        rd_en    <= 1'b1;
                        rd_addr  <= '0;
                    end
                end

                RD_READ: begin
                    rd_addr    <= rd_addr + 1;
                    rd_counter <= rd_counter + 1;

                    if (rd_counter >= READ_LAT) begin
                        automatic int idx = rd_counter - READ_LAT;
                        if (idx < MATRIX_SIZE) begin
                            softmax_input[idx] <= rd_data;
                            $display("t=%0t | rd_addr=%0d | softmax_input[%0d] = %0d",
                                     $time, rd_addr, idx, $signed(rd_data));
                        end
                    end

                    if (rd_counter == MATRIX_SIZE + READ_LAT) begin
                        rd_en    <= 1'b0;
                        rd_state <= RD_DONE;
                        softmax_start_cnt <= 0;
                    end
                end

                RD_DONE: begin
                    if (softmax_start_cnt < 2) begin
                        softmax_start     <= 1'b1;
                        softmax_start_cnt <= softmax_start_cnt + 1;
                    end else begin
                        softmax_start <= 1'b0;
                    end
                end

                default: begin
                    rd_state      <= RD_IDLE;
                    rd_en         <= 1'b0;
                    rd_addr       <= '0;
                    rd_counter    <= '0;
                    softmax_start <= 1'b0;
                end

            endcase
        end
    end

    // =========================================================
    // Softmax block
    // =========================================================
    bugSoftmax32 u_softmax (
        .i_clk   (i_clk),
        .i_rst   (i_rst),
        .i_valid (softmax_start),
        .i_data  (softmax_input),
        .o_valid (softmax_valid),
        .o_data  (o_softmax)  // [31:0][15:0] unsigned Q0.16
    );

    // =========================================================
    // Flatten softmax output to BRAM
    // =========================================================
    outputFlattenRow u_flatten_softmax (
        .i_clk   (i_clk),
        .i_rst   (i_rst),
        .i_valid (softmax_valid),
        .matrix  (o_softmax),
        .o_done  (softmax_done),
        .wr_addr (wr_addr_output),
        .wr_en   (wr_en_output),
        .wr_data (wr_data_output)
    );

    // =========================================================
    // BRAM Softmax output
    // =========================================================
    blk_mem_gen_softmax u_bram_softmax (
        .clka (i_clk),
        .ena  (1'b1),
        .wea  (wr_en_output),
        .addra(wr_addr_output),
        .dina (wr_data_output),

        .clkb (i_clk),
        .enb  (probe_enb),
        .web  (1'b0),
        .addrb(probe_addrb),
        .dinb ('0),
        .doutb(probe_doutb)
    );

    // Done signal
    assign o_valid = softmax_done;

    // Testbench probe port B mapping
    assign probe_enb   = 1'b1;
    assign probe_addrb = i_probe_addr;

endmodule
