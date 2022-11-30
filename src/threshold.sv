`timescale 1ns / 1ps
`default_nettype none

`define MATH ({pixel_data_in[15:11], 3'b000} + {pixel_data_in[10:5], 2'b00} + {pixel_data_in[4:0], 3'b000})

module threshold #(
    parameter MASK = 215)(
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [7:0] hcount_in, //current hcount being read
    input wire [8:0] vcount_in, //current vcount being read
    input wire data_valid_in, 
    input wire [15:0] pixel_data_in, //incoming pixel

    output logic data_valid_out,
    output logic [15:0] pixel_data_out, //output pixels of data (blah make this packed)
    output logic [$clog2(320*240)-1:0] addr_out; 
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin 
        pixel_data_out <= 0; 
        hcount_out <= 0; 
        vcount_out <= 0; 
    end 
    
    pixel_data_out <= `MATH < MASK * 3 ? 8'd0 : 8'd255; 
    addr_out <= hcount_in + vcount_in * 240; 
    data_valid_out <= data_valid_in; 
    
  end


endmodule


`default_nettype wire
