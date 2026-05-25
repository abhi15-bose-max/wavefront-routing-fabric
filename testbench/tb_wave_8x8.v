module tb_wave_8x8;

reg clk;
reg rst;

wire [383:0] cost_out;

wave_grid_8x8 uut (

    .clk(clk),
    .rst(rst),
    .cost_out(cost_out)

);

integer i, r, c;

always #5 clk = ~clk;

initial begin

    clk = 0;
    rst = 1;

    #10;
    rst = 0;

    $display("=== WAVEFRONT ROUTING TEST ===");

    for (i = 0; i < 15; i = i + 1) begin

        #10;

        $display("Cycle %0d:", i);

        for (r = 0; r < 8; r = r + 1) begin

            for (c = 0; c < 8; c = c + 1) begin

                $write("%2d ",
                    cost_out[
                        ((r*8+c)*6) +: 6
                    ]
                );

            end

            $write("\n");

        end

        $display("-------------------------");

    end

    $finish;

end

endmodule
