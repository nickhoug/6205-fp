`timescale 1ns / 1ps
`default_nettype none

`define RANK_SIZE corner_width * rank_height //1120
`define SUIT_SIZE corner_width * suit_height //812

`define WITHIN_RANK (hcount > (left_edge + 4)) && (hcount <= (left_edge + 4 + corner_width)) && (vcount > top_edge) && (vcount < (top_edge + rank_height))
`define LEAVING_RANK (hcount > (left_edge + 4 + corner_width + 3)) && (vcount == (top_edge + rank_height - 1))

`include "iverilog_hack_kernel.svh"

module XOR_king #(
    parameter HEIGHT = 640, 
    parameter WIDTH = 480, 
    parameter corner_width = 28, 
    parameter rank_height = 40, 
    parameter suit_height = 29)(

    input wire clk, 
    input wire rst, 
    input wire [10:0] hcount, 
    input wire [9:0] vcount,
    input wire mask, 

    input wire [10:0] left_edge, 
    input wire [9:0] top_edge, 

    output logic [$clog2(`RANK_SIZE) - 1:0] king_score
  );

    //Latency: 2
    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(1),                       // Specify RAM data width
        .RAM_DEPTH(`RANK_SIZE),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(K.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) king_kernel (
        .addra(addr_read),     // Address bus, width determined from RAM_DEPTH
        .dina(0),
        .clka(clk),       // Clock
        .wea(0),         // Write enable
        .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst),       // Output reset (does not affect memory contents)
        .regcea(1),   // Output register enable
        .douta(kernel_data)      // RAM output data, width determined from RAM_WIDTH
    );

    //Latency: 2
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(1),
        .RAM_DEPTH(`RANK_SIZE))
        mask_input (
        //Write Side

        .addra(addr_write),
        .clka(clk),
        .wea(`WITHIN_RANK),
        .dina(mask),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst),
        .douta(),

        //Read Side 
        .addrb(addr_read),
        .dinb(0),
        .clkb(clk),
        .web(0),
        .enb(1),
        .rstb(rst),
        .regceb(1),
        .doutb(mask_data)
    );

    logic [$clog2(`RANK_SIZE) - 1:0] addr_write = 0;
    logic [$clog2(`RANK_SIZE) - 1:0] addr_read = 0;

    logic [$clog2(`RANK_SIZE) - 1:0] score = 0; 
    
    logic start_flag = 0; 
    logic end_flag = 0; 

    logic kernel_data; 
    logic mask_data; 

    always_ff @(posedge clk) begin

        if (`WITHIN_RANK) begin 
            addr_write <= addr_write + 1;
        end 

        if (`LEAVING_RANK) begin 
            addr_write <= 0; 
            start_flag <= 1; 
            addr_read <= 0;
        end 

        if (start_flag) begin 
            if (kernel_data ^ mask_data == 1) begin 
                score <= score + 1; 
            end 
            else if (addr_read == `RANK_SIZE - 1) begin 
                king_score <= score; 
                end_flag <= 1; 
                start_flag <= 0; 
            end 
            addr_read <= addr_read + 1; 
        end 

        if (end_flag) begin 
            addr_read <= 0; 
            addr_write <= 0;
            score <= 0; 
             
            start_flag <= 0; 
            end_flag <= 0; 
        end 

        if (rst) begin 
            addr_read <= 0; 
            addr_write <= 0;
            score <= 0; 

            start_flag <= 0; 
            end_flag <= 0; 
        end 
    end 

endmodule

`default_nettype wire
