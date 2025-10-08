module outputFlattenRow (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_valid,             // báo có vector softmax mới
    input  logic [15:0] matrix [31:0],       // vector 32 phần tử (Q0.16)

    output logic        o_done,              // báo đã ghi xong
    output logic [4:0]  wr_addr,             // địa chỉ BRAM (0..31)
    output logic        wr_en,               // enable ghi
    output logic [15:0] wr_data              // dữ liệu ghi
);

    typedef enum logic [1:0] {S_IDLE, S_WRITE, S_DONE} state_t;
    state_t state;

    logic [4:0] index;
    logic [15:0] matrix_reg [31:0];   // latch toàn bộ softmax output

    // latch input khi có valid
    always_ff @(posedge i_clk) begin
        if (i_valid) begin
            matrix_reg <= matrix;
        end
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state   <= S_IDLE;
            index   <= '0;
            wr_en   <= 1'b0;
            wr_addr <= '0;
            wr_data <= '0;
            o_done  <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    wr_en  <= 1'b0;
                    o_done <= 1'b0;
                    if (i_valid) begin
                        index <= 0;
                        state <= S_WRITE;
                    end
                end

                S_WRITE: begin
                    wr_en   <= 1'b1;
                    wr_addr <= index;
                    wr_data <= matrix_reg[index];

                    if (index == 31) begin
                        state  <= S_DONE;
                    end else begin
                        index <= index + 1;
                    end
                end

                S_DONE: begin
                    wr_en  <= 1'b0;
                    o_done <= 1'b1;
                    if (!i_valid) state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
