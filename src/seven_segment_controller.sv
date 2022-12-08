`timescale 1ns / 1ps
`default_nettype none

module seven_segment_controller #(parameter COUNT_TO = 'd100_000)
                        (input wire         clk_in,
                         input wire         rst_in,

                         input wire [1:0]     suit,  
                         input wire [3:0]     rank, 
                         input wire [6:0] suit_score, 
                         input wire [6:0] rank_score,

                         output logic[6:0]   cat_out,
                         output logic[7:0]   an_out
                        );

  logic [7:0]	segment_state;
  logic [31:0] segment_counter;
  logic [3:0]	routed_vals;

  logic [6:0]	led_out;
  logic [6:0]	led_out_basic;
  logic [6:0]	led_out_rank;
  logic [6:0]	led_out_suit;

  always_ff @(posedge clk_in) begin
    if (segment_state == 8'b0000_0100) begin //0
      routed_vals <= 4'b0000;
    end 
    if (segment_state == 8'b0000_1000) begin //suit_score (ones)
      routed_vals <= suit_score - suit_score/4'd10; 
    end 
    if (segment_state == 8'b0001_0000) begin //suit_score (tens)
      routed_vals <= suit_score/4'd10;
    end 
    if (segment_state == 8'b0010_0000) begin //0
      routed_vals <= 4'b0000;
    end 
    if (segment_state == 8'b0100_0000) begin //rank_score (ones)
      routed_vals <= rank_score - rank_score/4'd10;
    end 
    if (segment_state == 8'b1000_0000) begin //rank_score (tens)
      routed_vals <= rank_score/4'd10;
    end 
  end

  bto7s basic_numbers (.x_in(routed_vals), .s_out(led_out_basic));
  bto7s_rank rank     (.rank(rank), .s_out(led_out_rank));
  bto7s_suit suit     (.suit(suit), .s_out(led_out_suit));

  always_comb begin : led_out_route
    if (segment_state == 8'b0000_0001) begin 
      cat_out = ~led_out_suit;
    end
    if (segment_state == 8'b0000_0010) begin 
      cat_out = ~led_out_rank;
    end
    else begin 
      cat_out = ~led_out_basic; 
    end 
    an_out = ~segment_state;
  end

  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      segment_state <= 8'b0000_0001;
      segment_counter <= 32'b0;
    end else begin
      if (segment_counter == COUNT_TO) begin
        segment_counter <= 32'd0;
        segment_state <= {segment_state[6:0],segment_state[7]};
    	end else begin
    	  segment_counter <= segment_counter + 1;
    	end
    end
  end

endmodule // seven_segment_controller

`default_nettype wire