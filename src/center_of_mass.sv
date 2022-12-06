`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (input wire clk_in,
                      input wire rst_in,
                      input wire [10:0] x_in,
                      input wire [9:0]  y_in,
                      input wire valid_in,
                      input wire tabulate_in,
                      output logic [10:0] x_out,
                      output logic [9:0] y_out,
                      output logic valid_out);

  logic [28:0] total; //20 bit number; max value is 1024 * 768 = 786432 ~ 2**(19.58)
  logic [28:0] x_total; 
  logic [28:0] y_total; 
  logic [28:0] x_quotient; 
  logic [28:0] y_quotient; 
  logic [28:0] x_remainder; 
  logic [28:0] y_remainder; 
  logic [10:0] x_quotient_temp; 
  logic [ 9:0] y_quotient_temp;

  logic start_flag_x; 
  logic start_flag_y; 
  logic valid_x;
  logic valid_y; 
  logic error_x; 
  logic error_y; 
  logic busy_x; 
  logic busy_y; 

  logic single_cycle_flag;
  logic tabulate_in_old; 

  divider  #(.WIDTH(29)) com_math_x (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(x_total),
                .divisor_in(total),
                .data_valid_in(start_flag_x),
                .quotient_out(x_quotient),
                .remainder_out(x_remainder),
                .data_valid_out(valid_x),
                .error_out(error_x),
                .busy_out(busy_x));

  divider  #(.WIDTH(29)) com_math_y (
                .clk_in(clk_in),
                .rst_in(rst_in),
                .dividend_in(y_total),
                .divisor_in(total),
                .data_valid_in(start_flag_y),
                .quotient_out(y_quotient),
                .remainder_out(y_remainder),
                .data_valid_out(valid_y),
                .error_out(error_y),
                .busy_out(busy_y));

  always_ff @(posedge clk_in) begin
    tabulate_in_old <= tabulate_in;
    if (rst_in == 1'b1) begin 
      total <= 0; 
      x_total <= 0; 
      y_total <= 0;
      start_flag_x <= 0; 
      start_flag_y <= 0; 
      single_cycle_flag <= 0; 
    end 
    if (x_in >= 0 && x_in <= 1023 && y_in >= 0 && y_in <= 767) begin
      if (valid_in == 1'b1) begin 
        total <= total + 1'b1; 
        x_total <= x_total + x_in; 
        y_total <= y_total + y_in; 
      end 
    end 
    if (x_in == 1024 && y_in == 767) begin 
      start_flag_x <= 1'b1; 
      start_flag_y <= 1'b1; 
    end 
    if (valid_x == 1'b1) begin 
      x_quotient_temp <= {x_quotient[10:0]};
    end 
    if (valid_y == 1'b1) begin 
      y_quotient_temp <= {y_quotient[9:0]};
    end 
    if (tabulate_in == 1'b1 && tabulate_in_old == 0) begin  //rising edge
      if (x_quotient_temp == 0 && y_quotient_temp == 0) begin 
        valid_out <= 1'b0;
      end 
      else begin 
        valid_out <= 1'b1;
      end 
      x_out <= x_quotient_temp;
      y_out <= y_quotient_temp;
      single_cycle_flag <= 1'b1;
      start_flag_x <= 1'b0; 
      start_flag_y <= 1'b0;
      x_total <= 0; 
      y_total <= 0;
      total <= 0;
    end 
    if (single_cycle_flag == 1'b1) begin 
      valid_out <= 1'b0;
      single_cycle_flag <= 1'b0;
    end 
  end


endmodule

`default_nettype wire
