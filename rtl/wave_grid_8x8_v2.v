// =================================================================
// 8x8 Wavefront Grid Fabric - Version 2.1 (Multi-Run Fixed)
// =================================================================

module wave_grid_8x8_v2 #(
    parameter COST_WIDTH = 6
)(
    input clk,
    input rst,

    // Master Control Handshaking
    input          launch,
    output reg     done,

    // Dynamic Host Programming Configuration Interface (Write Path)
    input [63:0]   cfg_write_en,      
    input [1:0]    cfg_type_data,     
    input [3:0]    cfg_weight_data,   

    // Readback Fields
    output [63:0]               wave_out_bus,
    output [(64*COST_WIDTH)-1:0] cost_out_bus,
    output [127:0]              pointer_out_bus,
    output [511:0]              timestamp_out_bus
);

    reg [7:0] global_time;
    wire [(64*COST_WIDTH)-1:0] cost_bus;
    wire [63:0]                target_signals;

    genvar r, c;
    generate
        for (r = 0; r < 8; r = r + 1) begin : rows
            for (c = 0; c < 8; c = c + 1) begin : cols

                localparam idx   = r * 8 + c;
                localparam idx_n = (r - 1) * 8 + c;
                localparam idx_s = (r + 1) * 8 + c;
                localparam idx_e = r * 8 + (c + 1);
                localparam idx_w = r * 8 + (c - 1);

                reg [1:0] cell_type_storage;
                reg [3:0] terrain_weight_storage;

                // Configuration Storage Block (Untouched by launch cycles)
                always @(posedge clk or posedge rst) begin
                    if (rst) begin
                        cell_type_storage      <= 2'b00; 
                        terrain_weight_storage <= 4'd1;  
                    end else if (cfg_write_en[idx]) begin
                        cell_type_storage      <= cfg_type_data;
                        terrain_weight_storage <= cfg_weight_data;
                    end
                end

                assign target_signals[idx] = (cell_type_storage == 2'b11) && wave_out_bus[idx];

                wave_cell_v2 #(
                    .COST_WIDTH(COST_WIDTH)
                ) cell_inst (
                    .clk(clk),
                    .rst(rst),

                    .north_cost( (r == 0) ? {COST_WIDTH{1'b0}} : cost_bus[idx_n*COST_WIDTH +: COST_WIDTH] ),
                    .south_cost( (r == 7) ? {COST_WIDTH{1'b0}} : cost_bus[idx_s*COST_WIDTH +: COST_WIDTH] ),
                    .east_cost(  (c == 7) ? {COST_WIDTH{1'b0}} : cost_bus[idx_e*COST_WIDTH +: COST_WIDTH] ),
                    .west_cost(  (c == 0) ? {COST_WIDTH{1'b0}} : cost_bus[idx_w*COST_WIDTH +: COST_WIDTH] ),

                    .type_in(cell_type_storage),
                    .weight_in(terrain_weight_storage),
                    .launch(launch),
                    .global_time(global_time),

                    .wave_out(wave_out_bus[idx]),
                    .cost_reg(cost_bus[idx*COST_WIDTH +: COST_WIDTH]),
                    .pointer_reg(pointer_out_bus[idx*2 +: 2]),
                    .timestamp_reg(timestamp_out_bus[idx*8 +: 8])
                );

                assign cost_out_bus[idx*COST_WIDTH +: COST_WIDTH] = cost_bus[idx*COST_WIDTH +: COST_WIDTH];

            end
        end
    endgenerate

    // Global Execution Handshake Engine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            global_time <= 8'h00;
            done        <= 1'b0;
        end else if (launch) begin
            if (|target_signals) begin
                done <= 1'b1; 
            end else if (!done) begin
                global_time <= global_time + 1'b1;
            end
        end else begin
            global_time <= 8'h00;
            done        <= 1'b0;
        end
    end

endmodule
