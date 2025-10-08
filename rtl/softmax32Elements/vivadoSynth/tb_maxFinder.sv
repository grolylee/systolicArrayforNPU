`timescale 1ns/1ps

module tb_maxFinder;

    parameter int BIT_WIDTH = 16;
    parameter int N = 8;

    // DUT signals
    logic                        i_clk;
    logic                        i_rst;
    logic                        i_valid;
    logic                        o_valid;
    logic signed  [N-1:0][BIT_WIDTH-1:0] i_data;
    logic signed [BIT_WIDTH-1:0] o_dataMax;

    // Instantiate DUT
    maxFinder #(
        .BIT_WIDTH(BIT_WIDTH),
        .N(N)
    ) dut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_valid(i_valid),
        .i_data(i_data),
        .o_dataMax(o_dataMax),
        .o_valid(o_valid)
    );

    // Clock
    always #5 i_clk = ~i_clk;

    // Data rows (3 × 8 × 16-bit, với literal signed chuẩn)
    logic signed  [2:0][N-1:0][BIT_WIDTH-1:0] row_data = '{
        '{ 16'sd10,   16'sd20,   16'sd15,  -16'sd5, 
           16'sd0,   -16'sd30,   16'sd40,   16'sd5 },
        '{ -16'sd100, -16'sd50, -16'sd20, -16'sd70, 
          -16'sd90,  -16'sd10, -16'sd30, -16'sd80 },
        '{ 16'sd5,   16'sd100,  16'sd25,   16'sd88, 
           16'sd43,  16'sd77,   16'sd66,   16'sd22 }
    };

    // Main stimulus
    initial begin
        $display("=== TEST maxFinder ===");

        i_clk   = 0;
        i_rst   = 1;
        i_valid = 0;
        i_data  = '{default:0};

        #20 i_rst = 0;

        for (int row = 0; row < 3; row++) begin
            i_data  = row_data[row];
            i_valid = 1;
            @(posedge i_clk);
            i_valid = 0;

            wait(o_valid);
            @(posedge i_clk);

            #2;
            $write("Row %0d input = { ", row);
            for (int j = 0; j < N; j++) begin
                $write("%0d ", i_data[j]);
            end
            $write("} | Max = %0d\n", o_dataMax);
        end

        #20;
        $display("=== FINISH TEST ===");
        $finish;
    end

endmodule
