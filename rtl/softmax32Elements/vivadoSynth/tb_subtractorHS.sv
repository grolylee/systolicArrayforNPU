`timescale 1ns / 1ps

module tb_subtractorHS;

    parameter int BIT_WIDTH = 16;
    parameter int N = 8;
    parameter int STAGES = $clog2(N);

    // Clock and reset
    logic i_clk;
    logic i_rst;

    // Inputs
    logic i_valid;
    logic signed [N-1:0][BIT_WIDTH-1:0] i_data;

    // Outputs
    logic signed [N-1:0][BIT_WIDTH-1:0] o_data;
    logic o_valid;

    // Instantiate DUT
    subtractorHS #(
        .BIT_WIDTH(BIT_WIDTH),
        .N(N),
        .STAGES(STAGES)
    ) dut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_valid),
        .i_data(i_data),
        .o_data(o_data),
        .o_valid(o_valid)
    );

    // Clock generation
    always #5 i_clk = ~i_clk;  // 100MHz

    // Helper: convert Q2.14 to real
    function real q2p14_to_real(input signed [15:0] val);
        return val / 16384.0;
    endfunction

    function real q4p12_to_real(input signed [15:0] val);
        return val / 4096.0;
    endfunction

    // Declare latency outside
    int latency = STAGES + 2;

    // Test process
    initial begin
        i_clk = 0;
        i_rst = 1;
        i_valid = 0;
        i_data = '{default: 0};

        // Reset
        #20;
        i_rst = 0;

        // Wait one cycle
        @(posedge i_clk);

        // Test input
        i_data[0] = $rtoi(1.5  * 16384);  // 1.5
        i_data[1] = $rtoi(-0.25 * 16384); // -0.25
        i_data[2] = $rtoi(0.75 * 16384);  // 0.75
        i_data[3] = $rtoi(2.0  * 16384);  // 2.0 (max)
        i_data[4] = $rtoi(-1.0 * 16384);  // -1.0
        i_data[5] = $rtoi(1.0 * 16384);   // 1.0
        i_data[6] = $rtoi(0.0 * 16384);   // 0.0
        i_data[7] = $rtoi(-0.5 * 16384);  // -0.5

        @(posedge i_clk);
        i_valid = 1;

        @(posedge i_clk);
        i_valid = 0;

        // Wait for output valid
        repeat (latency) @(posedge i_clk);

        // Display result
        if (o_valid) begin
            $display("\n===== KẾT QUẢ =====");
            for (int i = 0; i < N; i++) begin
                automatic real in_real  = q2p14_to_real(i_data[i]);
                automatic real out_real = q4p12_to_real(o_data[i]);
                $display("i_data[%0d] = %f --> o_data[%0d] = %f", i, in_real, i, out_real);
            end
        end else begin
            $display("Not o_Valid");
        end

        #10;
        $finish;
    end

endmodule
