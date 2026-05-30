`timescale 1ns / 1ps

module wave_grid_8x8_v2_tb;

    parameter COST_WIDTH = 6;

    reg clk;
    reg rst;
    reg launch;
    wire done;

    reg [63:0]   cfg_write_en;
    reg [1:0]    cfg_type_data;
    reg [3:0]    cfg_weight_data;

    wire [63:0]               wave_out_bus;
    wire [(64*COST_WIDTH)-1:0] cost_out_bus;
    wire [127:0]              pointer_out_bus;
    wire [511:0]              timestamp_out_bus;

    wave_grid_8x8_v2 #(
        .COST_WIDTH(COST_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .launch(launch),
        .done(done),
        .cfg_write_en(cfg_write_en),
        .cfg_type_data(cfg_type_data),
        .cfg_weight_data(cfg_weight_data),
        .wave_out_bus(wave_out_bus),
        .cost_out_bus(cost_out_bus),
        .pointer_out_bus(pointer_out_bus),
        .timestamp_out_bus(timestamp_out_bus)
    );

    always #5 clk = ~clk;

    integer r, c, i;
    integer cell_idx;
    
    task clear_grid;
        begin
            cfg_write_en    = 64'h0;
            cfg_type_data   = 2'b00; 
            cfg_weight_data = 4'd1;  
            for (i = 0; i < 64; i = i + 1) begin
                @(posedge clk);
                cfg_write_en = (64'b1 << i);
            end
            @(posedge clk);
            cfg_write_en = 64'h0;
        end
    endtask

    task program_cell(input [5:0] target_index, input [1:0] target_type, input [3:0] target_weight);
        begin
            @(posedge clk);
            cfg_write_en    = (64'b1 << target_index);
            cfg_type_data   = target_type;
            cfg_weight_data = target_weight;
            @(posedge clk);
            cfg_write_en    = 64'h0;
        end
    endtask

    task print_terminal_matrices;
        begin
            $display("\n--- CURRENT ACCELERATOR GRID FIELD STATE ---");
            
            $display("\n[ARRIVAL TIMESTAMPS FIELD]");
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) begin
                    cell_idx = r * 8 + c;
                    $write("%4d", timestamp_out_bus[cell_idx*8 +: 8]);
                end
                $display("");
            end

            $display("\n[ACCUMULATED PATH COSTS FIELD]");
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) begin
                    cell_idx = r * 8 + c;
                    $write("%4d", cost_out_bus[cell_idx*COST_WIDTH +: COST_WIDTH]);
                end
                $display("");
            end

            $display("\n[BACK-POINTER ARROWS FIELD] (0:N, 1:S, 2:E, 3:W)");
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) begin
                    cell_idx = r * 8 + c;
                    if (wave_out_bus[cell_idx])
                        $write("%4d", pointer_out_bus[cell_idx*2 +: 2]);
                    else
                        $write("   .");
                end
                $display("");
            end
            $display("------------------------------------------------");
        end
    endtask

    initial begin
        clk             = 0;
        rst             = 1;
        launch          = 0;
        cfg_write_en    = 64'h0;
        cfg_type_data   = 2'b00;
        cfg_weight_data = 4'h0;

        #20;
        rst = 0;
        #10;

        // -------------------------------------------------------------
        // TB1: BASIC UNIFORM PROPAGATION PROFILE
        // -------------------------------------------------------------
        $display("\n=================================================");
        $display("STARTING TB1: BASIC PROPAGATION (UNIFORM FIELDS)");
        $display("=================================================");
        clear_grid();
        program_cell(6'd0,  2'b10, 4'd1); 
        program_cell(6'd63, 2'b11, 4'd1); 

        launch = 1;
        @(posedge done);
        #1;
        print_terminal_matrices();
        launch = 0;
        #20; // Allow state lines to settle

        // -------------------------------------------------------------
        // TB2: OBSTACLE PATH BENDING PROFILE
        // -------------------------------------------------------------
        $display("\n=================================================");
        $display("STARTING TB2: OBSTACLE PATH BENDING PROFILE");
        $display("=================================================");
        clear_grid();
        program_cell(6'd0,  2'b10, 4'd1); 
        program_cell(6'd63, 2'b11, 4'd1); 
        
        for (c = 1; c <= 6; c = c + 1) begin
            program_cell(3 * 8 + c, 2'b01, 4'd1); 
        end

        launch = 1;
        @(posedge done);
        #1;
        print_terminal_matrices();
        launch = 0;
        #20;

        // -------------------------------------------------------------
        // TB3: VARIABLE WEIGHTED TERRAIN PROFILE
        // -------------------------------------------------------------
        $display("\n=================================================");
        $display("STARTING TB3: VARIABLE WEIGHTED TERRAIN PROFILE");
        $display("=================================================");
        clear_grid();
        program_cell(6'd0,  2'b10, 4'd1); 
        program_cell(6'd63, 2'b11, 4'd1); 
        
        for (r = 2; r <= 5; r = r + 1) begin
            for (c = 2; c <= 5; c = c + 1) begin
                program_cell(r * 8 + c, 2'b00, 4'd10);
            end
        end

        launch = 1;
        @(posedge done);
        #1;
        print_terminal_matrices();
        launch = 0;
        #20;

        // -------------------------------------------------------------
        // TB4: TIMESTAMP CAPTURE ACCURACY TEST
        // -------------------------------------------------------------
        $display("\n=================================================");
        $display("STARTING TB4: TIMESTAMP CAPTURE ACCURACY TEST");
        $display("=================================================");
        clear_grid();
        program_cell(6'd0,  2'b10, 4'd1);
        program_cell(6'd63, 2'b11, 4'd1);

        launch = 1;
        $display("Sampling Cell (1,1) timestamp freeze stability over active cycles:");
        for (i = 0; i < 6; i = i + 1) begin
            @(posedge clk);
            $display("   Cycle Window Counter: %0d | Cell(1,1) Active Waveout: %b | Latched Timestamp: %d", 
                     i, wave_out_bus[9], timestamp_out_bus[9*8 +: 8]);
        end
        
        @(posedge done);
        $display("[ACCELERATOR] TB4 Completed Execution clean.");
        launch = 0;
        #20;

        // -------------------------------------------------------------
        // TB5: CPU RUNTIME MAP PROGRAMMABILITY
        // -------------------------------------------------------------
        $display("\n=================================================");
        $display("STARTING TB5: CPU RUNTIME MAP PROGRAMMABILITY");
        $display("=================================================");
        clear_grid();
        
        program_cell(6'd18, 2'b10, 4'd1);  // Relocate START -> (2,2)
        program_cell(6'd45, 2'b11, 4'd1);  // Relocate TARGET -> (5,5)
        program_cell(6'd26, 2'b01, 4'd1);  
        program_cell(6'd27, 2'b01, 4'd1);  

        launch = 1;
        @(posedge done);
        $display("[ACCELERATOR] Custom remapped computation completed.");
        #1;
        print_terminal_matrices();
        launch = 0;
        #50;
        
        $display("\n=================================================");
        $display("ALL 5 ACCELERATOR TEST ARCHITECTURES EXECUTED SUCCESSFULLY.");
        $display("=================================================");
        $finish;
    end

endmodule
