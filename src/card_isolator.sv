`timescale 1ns / 1ps
`default_nettype none

module card_isolator #(
    parameter HEIGHT = 320, 
    parameter WIDTH = 240)(
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [$clog2(WIDTH) - 1: 0] right_edge, 
    input wire [$clog2(WIDTH) - 1: 0] left_edge,
    input wire [$clog2(HEIGHT) - 1: 0] top_edge,
    input wire [$clog2(HEIGHT) - 1: 0] bot_edge, 
    input wire start_flag; 
    input wire [15:0] pixel_data_in; 
 
    output logic [$clog2(HEIGHT*WIDTH) - 1: 0] addr_out, 

  );
    
    logic start_flag_old; 
    logic math_flag; 
    logic end_flag; 
 
    logic [$clog2(WIDTH) - 1:0] index_x; 
    logic [$clog2(HEIGHT) - 1:0] index_y;

    logic [x_width - 1: 0][y_width - 1: 0] suit_rank; //Width, height

    assign [$clog2(WIDTH) - 1:0] x_width = right_edge - left_edge; 
    assign [$clog2(HEIGHT) - 1:0] y_width = bot_edge - top_edge;

    assign [$clog2(WIDTH) - 1:0] corner_width = x_width / 7; 
    assign [$clog2(HEIGHT) - 1:0] corner_height = y_width / 4;

    always_ff @(posedge clk_in) begin
        start_flag_old <= start_flag; 

        if (start_flag_old = 0 && start_flag = 1) begin 
            index_x <= left_edge + 1; 
            index_y <= top_edge; 
            addr_out <= left_edge + top_edge * WIDTH; 
            math_flag <= 1; 
            end_flag <= 0; 
        end 

        if (math_flag) begin
            addr_out <= index_x + index_y * WIDTH; 
            index_x <= index_x + 1; 
            if (index_x == x_width) begin 
                index_x <= 0; 
                index_y <= index_y + 1; 
                if (index_y == y_width) begin 
                    end_flag <= 1;
                end 
            end 
        end 

        if (end_flag) begin 

        end 

        if (rst_in) begin
        end 
    end 

endmodule

`default_nettype wire
