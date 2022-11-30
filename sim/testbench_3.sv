`timescale 1ns / 1ps
`default_nettype none

`include "src/iverilog_hack_thresh.svh"

/******************************COMMANDS*********************************

iverilog -g2012 -o sim/testbench_3.out sim/testbench_3.sv src/xilinx_single_port_ram_read_first.v src/find_corners.sv src/card_isolator.sv

vvp sim/testbench_3.out

************************************************************************/

module testbench_3;

    logic clk; 
    logic rst; 

    logic find_corners_flag; 
    logic [15:0] pixel_data; 

    logic [16:0] addr; 
    logic data_valid_out; 
    logic [239:0] line_cache_out; 

    logic [7:0] right_edge; 
    logic [7:0] left_edge; 
    logic [8:0] top_edge; 
    logic [8:0] bot_edge; 

    xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(76800),                     // Specify RAM depth (number of entries) 1.2Mbits 
    .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(king_of_clubs_thresh_processed.mem)))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    card_input (
    .addra(addr),     // Address bus, width determined from RAM_DEPTH
    .dina(16'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(pixel_data)      // RAM output data, width determined from RAM_WIDTH
    );

    find_corners #(
    .HEIGHT(320), 
    .WIDTH(240))
    corner_finder (
    .clk_in(clk), 
    .rst_in(rst), 
    .find_corners_flag(find_corners_flag),
    .x_center(8'd114),
    .y_center(9'd153), 
    .pixel_data_in(pixel_data),  
    .addr_out(addr), 
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
        $dumpfile("sim/testbench_3.vcd");
        $dumpvars(0, testbench_3);
        $display("Starting Sim"); //print nice message

        find_corners_flag = 1'b0; 
        clk = 1'b1; 
        rst = 1'b0; 
        #10; 
        rst = 1'b1; 
        #10; 
        rst = 1'b0; 
        #10; 
        find_corners_flag = 1'b1;
        #10;
        find_corners_flag = 1'b0;
        #50000; 
        $display("Right: %d , Left: %d , Top: %d , Bot: %d ", right_edge, left_edge, top_edge, bot_edge);

        $display("Finishing Sim"); //print nice message
        $finish;
    end

endmodule 

`default_nettype wire