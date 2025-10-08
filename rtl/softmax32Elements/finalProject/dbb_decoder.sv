module dbb_decoder (
    input  logic clk,
    input  logic rst,
    input  logic i_start,   // start từ FSM chính
    input  logic i_mask,    // 1 = compute, 0 = skip
    output logic o_enable,  // cho phép SA chạy
    output logic o_done     // báo DONE (skip hoặc compute xong)
);
    typedef enum logic [1:0] {IDLE, CHECK, RUN, DONE} state_t;
    state_t state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else begin
            case (state)
                IDLE:   if (i_start) state <= CHECK;
                CHECK:  state <= (i_mask ? RUN : DONE);
                RUN:    state <= DONE;
                DONE:   state <= IDLE;

                // 👇 bổ sung default để tránh latch
                default: state <= IDLE;
            endcase
        end
    end

    // Output logic
    assign o_enable = (state == RUN);
    assign o_done   = (state == DONE);

endmodule
