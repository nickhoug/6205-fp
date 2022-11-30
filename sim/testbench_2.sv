`timescale 1ns / 1ps
`default_nettype none

`include "src/iverilog_hack.svh"

/******************************COMMANDS*********************************

iverilog -g2012 -o sim/testbench_2.out sim/testbench_2.sv src/xilinx_single_port_ram_read_first.v src/find_corners.sv 

vvp example.out

************************************************************************/

module testbench_2;

    logic clk; 
    logic rst; 

    logic find_corners_flag; 
    logic [15:0] pixel_data; 
    logic [239:0] memory_x = 240'h1000_0000_0000_0000_0000_FFFF_FFFF_FFFF_FFFF_FFFF_0000_0000_0000_0000_0000; 
    logic [319:0] memory_y = 320'h1000_0000_0000_0000_0000_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_0000_0000_0000_0000_0000;

    logic [16:0] addr_out; 
    logic data_valid_out; 
    logic [239:0] line_cache_out; 

    logic [7:0] right_edge; 
    logic [7:0] left_edge; 
    logic [8:0] top_edge; 
    logic [8:0] bot_edge; 

    find_corners #(
    .HEIGHT(320), 
    .WIDTH(240))
    corner_finder (
    .clk_in(clk), 
    .rst_in(rst), 
    .find_corners_flag(find_corners_flag),
    .x_center(8'd117),
    .y_center(9'd161), 
    .pixel_data_in(pixel_data),  
    .addr_out(addr_out), 
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
        $dumpfile("sim/testbench_2.vcd");
        $dumpvars(0, testbench_2);
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
        for (int i = 239; i >= 0; i = i - 1) begin 
            pixel_data = (memory_x[i] == 1) ? 16'h00FF : 0; 
            #10;
        end 
        for (int j = 319; j >= 0; j = j - 1) begin 
            pixel_data = (memory_y[j] == 1) ? 16'h00FF : 0; 
            #10;
        end 
        #20000; 

        $display("Finishing Sim"); //print nice message
        $finish;
    end

endmodule 

`default_nettype wire