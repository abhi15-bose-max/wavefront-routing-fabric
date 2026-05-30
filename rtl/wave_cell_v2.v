// =================================================================
// Wavefront Processing Element (Cell) - Version 2.1 (Multi-Run Fixed)
// =================================================================

module wave_cell_v2 #(
    parameter COST_WIDTH = 6
)(
    input clk,
    input rst,

    // Neighborhood Interface
    input [COST_WIDTH-1:0] north_cost,
    input [COST_WIDTH-1:0] south_cost,
    input [COST_WIDTH-1:0] east_cost,
    input [COST_WIDTH-1:0] west_cost,

    // CPU Dynamic Configurations
    input [1:0]            type_in,        
    input [3:0]            weight_in,      
    input                  launch,         // Active Execution Gate
    input [7:0]            global_time,    

    // Hardware Outputs / CPU Readback Fields
    output reg             wave_out,
    output reg [COST_WIDTH-1:0] cost_reg,
    output reg [1:0]       pointer_reg,
    output reg [7:0]       timestamp_reg
);

// Cell State Encoding
localparam FREE   = 2'b00;
localparam WALL   = 2'b01;
localparam START  = 2'b10;
localparam TARGET = 2'b11;

// Back-pointer Direction Encoding
localparam DIR_NORTH = 2'b00;
localparam DIR_SOUTH = 2'b01;
localparam DIR_EAST  = 2'b10;
localparam DIR_WEST  = 2'b11;

reg [COST_WIDTH-1:0] min_neighbor_cost;
reg [1:0]            best_direction;
reg                  neighbor_active;

// Combinational Neighbor Search 
always @(*) begin
    neighbor_active = (north_cost > 0) || (south_cost > 0) || (east_cost > 0) || (west_cost > 0);
    min_neighbor_cost = {COST_WIDTH{1'b1}};
    best_direction    = DIR_NORTH;

    if (north_cost > 0 && north_cost <= min_neighbor_cost) begin
        min_neighbor_cost = north_cost;
        best_direction    = DIR_NORTH;
    end
    if (south_cost > 0 && south_cost <= min_neighbor_cost) begin
        min_neighbor_cost = south_cost;
        best_direction    = DIR_SOUTH;
    end
    if (east_cost > 0 && east_cost <= min_neighbor_cost) begin
        min_neighbor_cost = east_cost;
        best_direction    = DIR_EAST;
    end
    if (west_cost > 0 && west_cost <= min_neighbor_cost) begin
        min_neighbor_cost = west_cost;
        best_direction    = DIR_WEST;
    end
end

// Synchronous Propagation Logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        wave_out      <= 1'b0;
        cost_reg      <= {COST_WIDTH{1'b0}};
        pointer_reg   <= 2'b00;
        timestamp_reg <= 8'h00;
    end else if (!launch) begin
        // CRITICAL FIX: Flush transient wave state when launch is low,
        // allowing successive multi-run passes without destroying register configurations.
        wave_out      <= 1'b0;
        cost_reg      <= {COST_WIDTH{1'b0}};
        pointer_reg   <= 2'b00;
        timestamp_reg <= 8'h00;
    end else begin
        case (type_in)
            START: begin
                wave_out      <= 1'b1;
                cost_reg      <= {{ (COST_WIDTH-1){1'b0} }, 1'b1}; 
                pointer_reg   <= 2'b00;
                timestamp_reg <= 8'h00; 
            end

            WALL: begin
                wave_out      <= 1'b0;
                cost_reg      <= {COST_WIDTH{1'b0}};
                pointer_reg   <= 2'b00;
                timestamp_reg <= 8'h00;
            end

            FREE: begin
                if (!wave_out && neighbor_active) begin
                    wave_out      <= 1'b1;
                    cost_reg      <= min_neighbor_cost + weight_in;
                    pointer_reg   <= best_direction;
                    timestamp_reg <= global_time;
                end
            end

            TARGET: begin
                if (!wave_out && neighbor_active) begin
                    wave_out      <= 1'b1; 
                    cost_reg      <= min_neighbor_cost + weight_in;
                    pointer_reg   <= best_direction; 
                    timestamp_reg <= global_time;
                end
            end
        endcase
    end
end

endmodule
