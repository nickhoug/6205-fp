`timescale 1ns / 1ps
`default_nettype none

`include "src/iverilog_hack_test.svh"

/******************************COMMANDS*********************************

iverilog -g2012 -o sim/testbench_1.out sim/testbench_1.sv src/buffer.sv src/convolution.sv src/filter.sv src/kernels.sv src/xilinx_single_port_ram_read_first.v src/xilinx_true_dual_port_read_first_1_clock_ram.v src/threshold.sv src/center_of_mass.sv src/divider.sv

vvp sim/testbench_1.out

************************************************************************/

module testbench_1;

    logic [16:0] addr; 
    logic [16:0] addr_corners;
    logic [16:0] addr_thresh;

    logic [15:0] ram_out;
    logic [15:0] threshold_out;
    logic [15:0] ram_threshold_out;

    logic threshold_valid_in; 
    logic threshold_valid_out; 

    logic [15:0] memory [0:76799]; 

    logic clk; 
    logic rst; 
 
    logic [7:0] hcount_in; 
    logic [7:0] hcount_out;
    logic [7:0] com_x;

    logic [8:0] vcount_in; 
    logic [8:0] vcount_out; 
    logic [8:0] com_y; 

    logic com_valid_in = 0; 
    logic com_valid_out;
    logic com_tabulate = 0; 

    logic [7:0] right_edge; 
    logic [7:0] left_edge; 
    logic [8:0] top_edge; 
    logic [8:0] bot_edge; 

    xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(76800),                     // Specify RAM depth (number of entries) 1.2Mbits 
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(ace_of_hearts_test.mem)))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    card_input (
    .addra(addr),     // Address bus, width determined from RAM_DEPTH
    .dina(16'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(ram_out)      // RAM output data, width determined from RAM_WIDTH
    );

    xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(76800),                     // Specify RAM depth (number of entries) 1.2Mbits 
    .RAM_PERFORMANCE("LOW_LATENCY")) // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    thresholded_card (
    .addra(addr_thresh),     // Address bus, width determined from RAM_DEPTH
    .dina(threshold_out),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(threshold_valid_out),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(ram_threshold_out)      // RAM output data, width determined from RAM_WIDTH
    );

    threshold thresholder (
    .clk_in(clk), //system clock
    .rst_in(rst), //system reset

    .hcount_in(hcount_in), //current hcount being read
    .vcount_in(vcount_in), //current vcount being read
    .data_valid_in(threshold_valid_in), 
    .pixel_data_in(ram_out), //incoming pixel

    .data_valid_out(threshold_valid_out),
    .pixel_data_out(threshold_out), //output pixels of data (blah make this packed)
    .addr_out()
    );

    center_of_mass COM (
    .clk_in(clk),
    .rst_in(rst),
    .x_in(hcount_out),
    .y_in(vcount_out),
    .valid_in(threshold_valid_out),
    .tabulate_in(com_tabulate),
    .x_out(com_x),
    .y_out(com_y),
    .valid_out(com_valid_out)
    );

    find_corners #(
    .HEIGHT(320), 
    .WIDTH(240))
    corner_finder (
    .clk_in(clk), 
    .rst_in(rst), 
    .find_corners_flag(com_valid_out),
    .x_center(com_x),
    .y_center(com_y), 
    .pixel_data_in(ram_threshold_out),  
    .addr_out(addr_corners), 
    .data_valid_out(data_valid_out),
    .right_edge(right_edge), 
    .left_edge(left_edge), 
    .top_edge(top_edge), 
    .bot_edge(bot_edge)
    );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk = !clk;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("sim/testbench_1.vcd");
        $dumpvars(0, testbench_1);
        $display("Starting Sim"); //print nice message
        
        rst = 0;
        clk = 1; 
        threshold_valid_in = 0; 
        addr = 0; 
        #10
        rst = 1; 
        #10
        rst = 0; 

        /**************************THRESHOLDING + MASK**********************************/

        for (int j = 0; j < 320; j = j + 1) begin 
            for (int i = 0; i < 240; i = i + 1) begin 
                addr = i + (j * 240); 
                hcount_in = i; 
                vcount_in = j;
                threshold_valid_in = 1;
                #20;
                memory[hcount_out + vcount_out * 240] = threshold_out; 
                com_valid_in = (threshold_out == 8'hFF) ? 1'b1 : 1'b0; 
                #10;
                com_valid_in = 0; 
            end 
        end 

        addr = 240 + (320 * 240);
        hcount_in = 8'd240; 
        vcount_in = 9'd320;
        #10;
        memory[hcount_out + vcount_out * 240] = threshold_out;
        com_valid_in = (threshold_out == 8'hFF) ? 1'b1 : 1'b0;
        #10; 
        com_valid_in = 0;
        #50; 

        /************************** CENTER OF MASS **********************************/

        #2000; 
        com_tabulate = 1; 
        #10; 
        com_tabulate = 0;
        #200;

        $display("X COM: %d , Y COM: %d ", com_x, com_y);
        $display("Right: %d , Left: %d , Top: %d , Bot: %d ", right_edge, left_edge, top_edge, bot_edge)

        /************************** FIND CORNERS **********************************/

        

        $writememh("mem_thresh/king_of_clubs_thresh.mem", memory);


        $display("Finishing Sim"); //print nice message
        $finish;

    end

endmodule 

`default_nettype wire