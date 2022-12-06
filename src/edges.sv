`timescale 1ns / 1ps
`default_nettype none

`define START_ADDR_X y_center * WIDTH
`define END_ADDR_X y_center * WIDTH + WIDTH - 1

`define START_ADDR_Y x_center
`define END_ADDR_Y (HEIGHT - 1) * WIDTH + x_center

`define RIGHT_EDGE 16'hFF_00
`define LEFT_EDGE 16'h00_FF

`define TOP_EDGE 16'h00_FF
`define BOTTOM_EDGE 16'hFF_00

`define CHECK_SIZE 16
`define STARTING_SHIFT `CHECK_SIZE/2

module edges #(
    parameter HEIGHT = 320, 
    parameter WIDTH = 240)(
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire find_corners_flag,
    input wire [$clog2(WIDTH) - 1: 0] x_center, //8 bits
    input wire [$clog2(HEIGHT) - 1: 0] y_center, //9 bits
    input wire pixel_data_in,  

    output logic [$clog2(WIDTH*HEIGHT) - 1:0] addr_out, // 17 bits 
    output logic data_valid_out,
    output logic [$clog2(WIDTH) - 1: 0] right_edge, 
    output logic [$clog2(WIDTH) - 1: 0] left_edge,
    output logic [$clog2(HEIGHT) - 1: 0] top_edge,
    output logic [$clog2(HEIGHT) - 1: 0] bot_edge
  );

logic delay_flag = 1'b0; 
logic start_flag_x = 1'b0; 
logic start_flag_y = 1'b0;
logic find_corners_flag_old; 
logic end_flag = 1'b0; 

logic check_flag_right = 1'b0; 
logic check_flag_left = 1'b0;
logic check_flag_top = 1'b0;
logic check_flag_bot = 1'b0;

logic [WIDTH - 1: 0] line_cache_x;
logic [WIDTH - 1: 0] line_cache_rst_x; 
logic [$clog2(WIDTH) - 1:0] index_x; 

logic [HEIGHT - 1: 0] line_cache_y;
logic [HEIGHT - 1: 0] line_cache_rst_y; 
logic [$clog2(HEIGHT) - 1:0] index_y;

logic [$clog2(WIDTH - `STARTING_SHIFT) - 1:0] shift_reg_width; 
logic [$clog2(HEIGHT - `STARTING_SHIFT) - 1:0] shift_reg_height; 

logic pixel_data_in_thresh; 

logic busy = 0; 

assign pixel_data_in_thresh = pixel_data_in; 

always_ff @(posedge clk_in) begin
    find_corners_flag_old <= find_corners_flag;

    if (find_corners_flag_old == 0 && find_corners_flag == 1 && busy == 0) begin
        delay_flag <= 1; 
        addr_out <= `START_ADDR_X; 
        index_x <= WIDTH - 1; 
        index_y <= HEIGHT - 1;
        busy <= 1; 
    end

    if (delay_flag == 1'b1) begin 
        start_flag_x <= 1;
        delay_flag <= 0; 
    end 

    if (start_flag_x == 1) begin 
        if (addr_out == `END_ADDR_X) begin 
            start_flag_x <= 0;
            start_flag_y <= 1;
            line_cache_x[index_x] <= pixel_data_in_thresh; 
            line_cache_rst_x[index_x] <= pixel_data_in_thresh;
            index_x <= 0; 
            addr_out <= `START_ADDR_Y;  
        end else begin 
            addr_out <= addr_out + 1; 
            line_cache_x[index_x] <= pixel_data_in_thresh; 
            line_cache_rst_x[index_x] <= pixel_data_in_thresh;
            index_x <= index_x - 1; 
        end 
    end 

    if (start_flag_y == 1) begin 
        if (addr_out == `END_ADDR_Y) begin
            start_flag_y <= 0;
            check_flag_right <= 1;
            line_cache_y[index_y] <= pixel_data_in_thresh; 
            line_cache_rst_y[index_y] <= pixel_data_in_thresh;
            index_y <= 0;
            shift_reg_width <= `STARTING_SHIFT;
            shift_reg_height <= `STARTING_SHIFT - 1;
        end else begin
            addr_out <= addr_out + WIDTH;
            line_cache_y[index_y] <= pixel_data_in_thresh; 
            line_cache_rst_y[index_y] <= pixel_data_in_thresh;
            index_y <= index_y - 1;  
        end
    end 

    if (check_flag_right == 1) begin 
        if (line_cache_x[`CHECK_SIZE - 1: 0] == `RIGHT_EDGE) begin 
            right_edge <= (WIDTH - 1) - shift_reg_width - 1; 
            line_cache_x <= line_cache_rst_x; 
            shift_reg_width <= `STARTING_SHIFT - 1;
            check_flag_right <= 0;
            check_flag_left <= 1;
        end 
        if (shift_reg_width == WIDTH - `STARTING_SHIFT) begin
            check_flag_right <= 0; 
            shift_reg_width <= 0;
            end_flag <= 1;
        end 
        if (line_cache_x[`CHECK_SIZE - 1: 0] != `RIGHT_EDGE) begin 
            line_cache_x <= line_cache_x >> 1; 
            shift_reg_width <= shift_reg_width + 1;
        end 
    end 

    if (check_flag_left == 1) begin 
        if (line_cache_x[WIDTH - 1: WIDTH - `CHECK_SIZE] == `LEFT_EDGE) begin 
            left_edge <= shift_reg_width - 1; 
            line_cache_x <= line_cache_rst_x; 
            shift_reg_width <= `STARTING_SHIFT;
            check_flag_left <= 0;
            check_flag_top <= 1;
        end 
        if (shift_reg_width == WIDTH - `STARTING_SHIFT) begin
            check_flag_left <= 0; 
            shift_reg_width <= 0;
            end_flag <= 1;
        end 
        if (line_cache_x[WIDTH - 1: WIDTH - `CHECK_SIZE] != `LEFT_EDGE) begin 
            line_cache_x <= line_cache_x << 1; 
            shift_reg_width <= shift_reg_width + 1;
        end 
    end

    if (check_flag_top == 1) begin 
        if (line_cache_y[HEIGHT - 1: HEIGHT - `CHECK_SIZE] == `TOP_EDGE) begin 
            top_edge <= shift_reg_height; 
            line_cache_y <= line_cache_rst_y; 
            shift_reg_height <= `STARTING_SHIFT;
            check_flag_top <= 0;
            check_flag_bot <= 1;
        end 
        if (shift_reg_height == HEIGHT - `STARTING_SHIFT) begin
            check_flag_top <= 0; 
            shift_reg_height <= 0;
            end_flag <= 1;
        end 
        if (line_cache_y[HEIGHT - 1: HEIGHT - `CHECK_SIZE] != `TOP_EDGE) begin 
            line_cache_y <= line_cache_y << 1; 
            shift_reg_height <= shift_reg_height + 1;
        end 
    end

    if (check_flag_bot == 1) begin 
        if (line_cache_y[`CHECK_SIZE - 1: 0] == `BOTTOM_EDGE) begin 
            bot_edge <= (HEIGHT - 1) - shift_reg_height; 
            line_cache_y <= line_cache_rst_y; 
            shift_reg_height <= `STARTING_SHIFT;
            check_flag_bot <= 0;
            end_flag <= 1; 
            data_valid_out <= 1; 
        end 
        if (shift_reg_height == HEIGHT - `STARTING_SHIFT) begin
            check_flag_bot <= 0; 
            shift_reg_height <= 0;
            end_flag <= 1;
        end 
        if (line_cache_y[`CHECK_SIZE - 1: 0] != `BOTTOM_EDGE) begin 
            line_cache_y <= line_cache_y >> 1; 
            shift_reg_height <= shift_reg_height + 1;
        end 
    end

    if (end_flag == 1) begin 
        data_valid_out <= 0; 
        busy <= 0; 
    end 

    if (rst_in == 1) begin 
        right_edge <= 0; 
        left_edge <= 0; 
        top_edge <= 0;
        bot_edge <= 0; 

        line_cache_x <= 0; 
        line_cache_rst_x <= 0; 
        line_cache_y <= 0; 
        line_cache_rst_y <= 0; 

        index_x <= 0; 
        index_y <= 0; 

        data_valid_out <= 0; 
        addr_out <= 0; 

        shift_reg_height <= 0;
        shift_reg_width <= 0;

        busy <= 0;  

    end 
end

endmodule

`default_nettype wire
