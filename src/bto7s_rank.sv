`timescale 1ns / 1ps
`default_nettype none

module bto7s_rank(
        input wire [3:0]   rank,
        output logic [6:0] s_out
        );
  /* CARD MAPPINGS
      logic [3:0] ace_map = 4'b0001; 
      logic [3:0] two_map = 4'b0010;
      logic [3:0] three_map = 4'b0011;
      logic [3:0] four_map = 4'b0100;
      logic [3:0] five_map = 4'b0101;
      logic [3:0] six_map = 4'b0110;
      logic [3:0] seven_map = 4'b0111;
      logic [3:0] eight_map = 4'b1000;
      logic [3:0] nine_map = 4'b1001;
      logic [3:0] ten_map = 4'b1010;
      logic [3:0] jack_map = 4'b1011;
      logic [3:0] queen_map = 4'b1100;
      logic [3:0] king_map = 4'b1101;

  */

  logic [12:0] num;

  assign num[0] = rank == 4'b0001; //Ace
  assign num[1] = rank == 4'b0010; //Two
  assign num[2] = rank == 4'b0011; //Three
  assign num[3] = rank == 4'b0100; //Four
  assign num[4] = rank == 4'b0101; //Five
  assign num[5] = rank == 4'b0110; //Six
  assign num[6] = rank == 4'b0111; //Seven
  assign num[7] = rank == 4'b1000; //Eight
  assign num[8] = rank == 4'b1001; //Nine
  assign num[9] = rank == 4'b1010; //Ten
  assign num[10] = rank == 4'b1011; //Jack
  assign num[11] = rank == 4'b1100; //Queen
  assign num[12] = rank == 4'b1101; //King

  
  logic sa, sb, sc, sd, se, sf, sg;

  assign sa = num[0] || num[1] || num[2] || num[4] || num[5] || num[6] || num[7] || num[8] || num[9]  || num[10] || num[11];
  assign sb = num[0] || num[1] || num[2] || num[3] || num[6] || num[7] || num[8] || num[9] || num[10] || num[11] || num[12];
  assign sc = num[0] || num[2] || num[3] || num[4] || num[5] || num[6] || num[7] || num[8] || num[9]  || num[10] || num[11] || num[12];
  assign sd = num[1] || num[2] || num[4] || num[5] || num[7] || num[8] || num[9] || num[10];
  assign se = num[0] || num[1] || num[5] || num[7] || num[9] || num[10] || num[12];
  assign sf = num[0] || num[3] || num[4] || num[5] || num[6] || num[7] || num[8] || num[9] || num[11]  || num[11] || num[12];
  assign sg = num[0] || num[1] || num[2] || num[3] || num[4] || num[5] || num[7] || num[8] || num[11]  || num[12];

  assign s_out[6] = sg;
  assign s_out[5] = sf;
  assign s_out[4] = se;
  assign s_out[3] = sd;
  assign s_out[2] = sc;
  assign s_out[1] = sb;
  assign s_out[0] = sa;
  
endmodule

`default_nettype wire