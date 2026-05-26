// Keep 2^COST_WIDTH > Max Path Length to prevent overflow rollover to 0
module wave_cell #(
    parameter COST_WIDTH = 6
)(
    input clk,
    input rst,

    input [COST_WIDTH-1:0] north_cost,
    input [COST_WIDTH-1:0] south_cost,
    input [COST_WIDTH-1:0] east_cost,
    input [COST_WIDTH-1:0] west_cost,

    input [1:0] type_reg,

    output reg wave_out,
    output reg [COST_WIDTH-1:0] cost_reg,
    output reg [1:0] pointer_reg
);

localparam FREE   = 2'b00;
localparam WALL   = 2'b01;
localparam START  = 2'b10;
localparam TARGET = 2'b11;

localparam DIR_NORTH = 2'b00;
localparam DIR_SOUTH = 2'b01;
localparam DIR_EAST  = 2'b10;
localparam DIR_WEST  = 2'b11;

reg [COST_WIDTH-1:0] min_neighbor_cost;
reg [1:0] best_direction;
reg neighbor_active;

always @(*) begin

    neighbor_active =
        (north_cost > 0) ||
        (south_cost > 0) ||
        (east_cost > 0) ||
        (west_cost > 0);

    // Initialize to maximum value
    min_neighbor_cost = {COST_WIDTH{1'b1}};

    best_direction = DIR_NORTH;

    // Parallel minimum-cost comparison

    if (north_cost > 0 &&
        north_cost <= min_neighbor_cost) begin

        min_neighbor_cost = north_cost;
        best_direction = DIR_NORTH;

    end

    if (south_cost > 0 &&
        south_cost <= min_neighbor_cost) begin

        min_neighbor_cost = south_cost;
        best_direction = DIR_SOUTH;

    end

    if (east_cost > 0 &&
        east_cost <= min_neighbor_cost) begin

        min_neighbor_cost = east_cost;
        best_direction = DIR_EAST;

    end

    if (west_cost > 0 &&
        west_cost <= min_neighbor_cost) begin

        min_neighbor_cost = west_cost;
        best_direction = DIR_WEST;

    end

end

always @(posedge clk or posedge rst) begin

    if (rst) begin

        wave_out <= 0;
        cost_reg <= 0;
        pointer_reg <= 0;

    end

    else begin

        case (type_reg)

            START: begin

                wave_out <= 1;
                cost_reg <= 1;

            end

            WALL: begin

                wave_out <= 0;
                cost_reg <= 0;

            end

            FREE,
            TARGET: begin

                if (!wave_out && neighbor_active) begin

                    wave_out <= 1;

                    cost_reg <= min_neighbor_cost + 1;

                    pointer_reg <= best_direction;

                end

            end

        endcase

    end

end

endmodule
