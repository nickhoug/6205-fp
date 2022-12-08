`timescale 1ns / 1ps
`default_nettype none

module bto7s_suit(
        input wire [1:0]   suit,
        output logic [6:0] s_out
        );

  /* CARD MAPPINGS
      logic [1:0] diamond_map = 2'b00; 
      logic [1:0] heart_map = 2'b01;
      logic [1:0] club_map = 2'b10;
      logic [1:0] spade_map = 2'b11;
  */

  logic [3:0] num;

  assign num[0] = suit == 2'b00; //Diamond
  assign num[1] = suit == 2'b01; //Heart
  assign num[2] = suit == 2'b10; //Club
  assign num[3] = suit == 2'b11; //Spade

  logic sa, sb, sc, sd, se, sf, sg;

  assign sa = num[3];
  assign sb = num[0]; 
  assign sc = num[0] || num[1] || num[3];
  assign sd = num[0] || num[2] || num[3];
  assign se = num[0] || num[1] || num[2];
  assign sf = num[1] || num[3];
  assign sg = num[0] || num[1] || num[2] || num[3];

  assign s_out[6] = sg;
  assign s_out[5] = sf;
  assign s_out[4] = se;
  assign s_out[3] = sd;
  assign s_out[2] = sc;
  assign s_out[1] = sb;
  assign s_out[0] = sa;
  
endmodule

`default_nettype wire