`timescale 1ns / 1ps
`default_nettype none

`include "src/iverilog_hack.svh"

/******************************COMMANDS*********************************

iverilog -g2012 -o sim/top_level_tb.out sim/top_level_tb.sv 

vvp sim/testbench_3.out

************************************************************************/

module top_level_tb;

    logic clk; 
    logic rst; 

    logic [7:0] pixel_data; 
    logic [15:0] pixel_data_ram;
    logic [15:0] pixel_data_out;
    logic [16:0] addr; 

    logic href; 
    logic vsync; 
    logic cam_clk; 

    logic jbclk; 
    logic jblock;

    xilinx_single_port_ram_read_first #(
                                        .RAM_WIDTH(16),                       // Specify RAM data width
                                        .RAM_DEPTH(76800),                     // Specify RAM depth (number of entries) 1.2Mbits 
                                        .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
                                        .INIT_FILE(`FPATH(ace_of_hearts_test.mem)))          // Specify name/location of RAM initialization file if using one (leave blank if not)
                                        ace_of_hearts_input (
                                        .addra(addr),     // Address bus, width determined from RAM_DEPTH
                                        .dina(16'b0),       // RAM input data, width determined from RAM_WIDTH
                                        .clka(clk),       // Clock
                                        .wea(1'b0),         // Write enable
                                        .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
                                        .rsta(rst),       // Output reset (does not affect memory contents)
                                        .regcea(1'b1),   // Output register enable
                                        .douta(pixel_data_ram)      // RAM output data, width determined from RAM_WIDTH
                                        );

    top_level main (
                    .clk_100mhz(clk), //clock @ 100 mhz
                    .btnc(rst), //btnc (used for reset)
                    .ja(pixel_data), //lower 8 bits of data from camera
                    .jb({href, vsync, cam_clk}), //upper three bits from camera (return clock, vsync, hsync)

                    .jbclk(jbclk),  //signal we provide to camera
                    .jblock(jblock), //signal for resetting camera
                    .led(pixel_data_out)
    );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk = !clk;
    end

    always begin 
        #30; //period = 60 ns -> 16.67 MHz
        cam_clk = ~cam_clk; 
    end 

    //initial block...this is our test simulation
    initial begin
        $dumpfile("sim/top_level_tb.vcd");
        $dumpvars(0, top_level_tb);
        $display("Starting Sim"); //print nice message

        clk = 1'b1; 
        cam_clk = 1'b1; 
        rst = 1'b0; 
        #10; 
        rst = 1'b1; 
        #10; 
        rst = 1'b0; 
        #700; 
        vsync = 1'b0; 
        href = 1'b1; 
        for (int j = 0; j < 320; j = j + 1) begin 
            for (int i = 0; i < 240; i = i + 1) begin 
                addr = i + (j * 240); 
                #60; 
                pixel_data = pixel_data_ram[15:8];
                #60; 
                pixel_data = pixel_data_ram[7:0];
                #60; 
            end 
        end
        vsync = 1'b1; 
        href = 1'b0;
        #10000; 

        $display("Finishing Sim"); //print nice message
        $finish;
    end

endmodule 

`default_nettype wire