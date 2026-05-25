module wave_grid_8x8 (

    input clk,
    input rst,

    output [383:0] cost_out

);

parameter COST_WIDTH = 6;

genvar r, c;

// Flattened buses

wire [63:0] wave_bus;

wire [(64*COST_WIDTH)-1:0] cost_bus;

wire [127:0] pointer_bus;

generate

    for (r = 0; r < 8; r = r + 1) begin : rows

        for (c = 0; c < 8; c = c + 1) begin : cols

            // =================================================
            // CELL TYPES
            //
            // 00 = FREE
            // 01 = WALL
            // 10 = START
            // 11 = TARGET
            // =================================================

            localparam [1:0] CELL_TYPE =

                // START NODE
                (r == 0 && c == 0)

                ? 2'b10

                // TARGET NODE
                : ((r == 7 && c == 7)

                ? 2'b11

                // OBSTACLE WALL
                : ((r == 3 && c >= 1 && c <= 6)

                ? 2'b01

                // FREE SPACE
                : 2'b00));

            // =================================================
            // Flat indexing
            // =================================================

            localparam idx   = r*8 + c;

            localparam idx_n = (r-1)*8 + c;

            localparam idx_s = (r+1)*8 + c;

            localparam idx_e = r*8 + (c+1);

            localparam idx_w = r*8 + (c-1);

            // =================================================
            // Cell Instance
            // =================================================

            wave_cell #(
                .COST_WIDTH(COST_WIDTH)
            ) cell_inst (

                .clk(clk),
                .rst(rst),

                .north_cost(
                    (r == 0)
                    ? {COST_WIDTH{1'b0}}
                    : cost_bus[
                        idx_n*COST_WIDTH +: COST_WIDTH
                    ]
                ),

                .south_cost(
                    (r == 7)
                    ? {COST_WIDTH{1'b0}}
                    : cost_bus[
                        idx_s*COST_WIDTH +: COST_WIDTH
                    ]
                ),

                .east_cost(
                    (c == 7)
                    ? {COST_WIDTH{1'b0}}
                    : cost_bus[
                        idx_e*COST_WIDTH +: COST_WIDTH
                    ]
                ),

                .west_cost(
                    (c == 0)
                    ? {COST_WIDTH{1'b0}}
                    : cost_bus[
                        idx_w*COST_WIDTH +: COST_WIDTH
                    ]
                ),

                .type_reg(CELL_TYPE),

                .wave_out(
                    wave_bus[idx]
                ),

                .cost_reg(
                    cost_bus[
                        idx*COST_WIDTH +: COST_WIDTH
                    ]
                ),

                .pointer_reg(
                    pointer_bus[
                        idx*2 +: 2
                    ]
                )

            );

            assign cost_out[
                idx*COST_WIDTH +: COST_WIDTH
            ] = cost_bus[
                idx*COST_WIDTH +: COST_WIDTH
            ];

        end

    end

endgenerate

endmodule
