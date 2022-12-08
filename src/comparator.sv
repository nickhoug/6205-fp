`timescale 1ns / 1ps
`default_nettype none

`define RANK_SIZE corner_width * rank_height //1120
`define SUIT_SIZE corner_width * suit_height //812

module comparator #(
    parameter HEIGHT = 640, 
    parameter WIDTH = 480, 
    parameter corner_width = 28, 
    parameter rank_height = 40, 
    parameter suit_height = 29)(

    input wire [$clog2(`RANK_SIZE) - 1:0] two_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] three_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] four_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] five_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] six_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] seven_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] eight_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] nine_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] ten_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] jack_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] queen_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] king_score,
    input wire [$clog2(`RANK_SIZE) - 1:0] ace_score,

    input wire [$clog2(`SUIT_SIZE) - 1:0] spade_score, 
    input wire [$clog2(`SUIT_SIZE) - 1:0] diamond_score,
    input wire [$clog2(`SUIT_SIZE) - 1:0] heart_score,
    input wire [$clog2(`SUIT_SIZE) - 1:0] club_score,
    
    output logic [6:0] rank_score, 
    output logic [6:0] suit_score,
    output logic [5:0] card_map 
  );

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

logic [1:0] diamond_map = 2'b00; 
logic [1:0] heart_map = 2'b01;
logic [1:0] club_map = 2'b10;
logic [1:0] spade_map = 2'b11;

logic [$clog2(`RANK_SIZE) - 1:0] output_rank_score; 
logic [$clog2(`SUIT_SIZE) - 1:0] output_suit_score; 

logic [3:0] output_rank_map; 
logic [1:0] output_suit_map; 

assign card_map = {output_suit_map, output_rank_map}; //{suit, rank}
assign rank_score = 7'd100 - (output_rank_score * 7'd100) / `RANK_SIZE; //should be percentage where 100% is perfect
assign suit_score = 7'd100 - (output_suit_score * 7'd100) / `SUIT_SIZE;

always_comb begin : rank_ranking
  if ((two_score < three_score) && 
      (two_score < four_score) && 
      (two_score < five_score) && 
      (two_score < six_score) && 
      (two_score < seven_score) && 
      (two_score < eight_score) && 
      (two_score < nine_score) && 
      (two_score < ten_score) && 
      (two_score < jack_score) && 
      (two_score < queen_score) && 
      (two_score < king_score) && 
      (two_score < ace_score)) begin 
        output_rank_score = two_score;
        output_rank_map = two_map; 
  end
  if ((three_score < two_score) && 
      (three_score < four_score) && 
      (three_score < five_score) && 
      (three_score < six_score) && 
      (three_score < seven_score) && 
      (three_score < eight_score) && 
      (three_score < nine_score) && 
      (three_score < ten_score) && 
      (three_score < jack_score) && 
      (three_score < queen_score) && 
      (three_score < king_score) && 
      (three_score < ace_score)) begin 
        output_rank_score = three_score;
        output_rank_map = three_map;
  end
  if ((four_score < two_score) && 
      (four_score < three_score) && 
      (four_score < five_score) && 
      (four_score < six_score) && 
      (four_score < seven_score) && 
      (four_score < eight_score) && 
      (four_score < nine_score) && 
      (four_score < ten_score) && 
      (four_score < jack_score) && 
      (four_score < queen_score) && 
      (four_score < king_score) && 
      (four_score < ace_score)) begin 
        output_rank_score = four_score;
        output_rank_map = four_map;
  end
  if ((five_score < two_score) && 
      (five_score < three_score) && 
      (five_score < four_score) && 
      (five_score < six_score) && 
      (five_score < seven_score) && 
      (five_score < eight_score) && 
      (five_score < nine_score) && 
      (five_score < ten_score) && 
      (five_score < jack_score) && 
      (five_score < queen_score) && 
      (five_score < king_score) && 
      (five_score < ace_score)) begin 
        output_rank_score = five_score;
        output_rank_map = five_map;
  end
  if ((six_score < two_score) && 
      (six_score < three_score) && 
      (six_score < four_score) && 
      (six_score < five_score) && 
      (six_score < seven_score) && 
      (six_score < eight_score) && 
      (six_score < nine_score) && 
      (six_score < ten_score) && 
      (six_score < jack_score) && 
      (six_score < queen_score) && 
      (six_score < king_score) && 
      (six_score < ace_score)) begin 
        output_rank_score = six_score;
        output_rank_map = six_map;
  end
  if ((seven_score < two_score) && 
      (seven_score < three_score) && 
      (seven_score < four_score) && 
      (seven_score < five_score) && 
      (seven_score < six_score) && 
      (seven_score < eight_score) && 
      (seven_score < nine_score) && 
      (seven_score < ten_score) && 
      (seven_score < jack_score) && 
      (seven_score < queen_score) && 
      (seven_score < king_score) && 
      (seven_score < ace_score)) begin 
        output_rank_score = seven_score;
        output_rank_map = seven_map;
  end
  if ((eight_score < two_score) && 
      (eight_score < three_score) && 
      (eight_score < four_score) && 
      (eight_score < five_score) && 
      (eight_score < six_score) && 
      (eight_score < seven_score) && 
      (eight_score < nine_score) && 
      (eight_score < ten_score) && 
      (eight_score < jack_score) && 
      (eight_score < queen_score) && 
      (eight_score < king_score) && 
      (eight_score < ace_score)) begin 
        output_rank_score = eight_score;
        output_rank_map = eight_map;
  end
  if ((nine_score < two_score) && 
      (nine_score < three_score) && 
      (nine_score < four_score) && 
      (nine_score < five_score) && 
      (nine_score < six_score) && 
      (nine_score < seven_score) && 
      (nine_score < eight_score) && 
      (nine_score < ten_score) && 
      (nine_score < jack_score) && 
      (nine_score < queen_score) && 
      (nine_score < king_score) && 
      (nine_score < ace_score)) begin 
        output_rank_score = nine_score;
        output_rank_map = nine_map;
  end
  if ((ten_score < two_score) && 
      (ten_score < three_score) && 
      (ten_score < four_score) && 
      (ten_score < five_score) && 
      (ten_score < six_score) && 
      (ten_score < seven_score) && 
      (ten_score < eight_score) && 
      (ten_score < nine_score) && 
      (ten_score < jack_score) && 
      (ten_score < queen_score) && 
      (ten_score < king_score) && 
      (ten_score < ace_score)) begin 
        output_rank_score = ten_score;
        output_rank_map = ten_map;
  end
  if ((jack_score < two_score) && 
      (jack_score < three_score) && 
      (jack_score < four_score) && 
      (jack_score < five_score) && 
      (jack_score < six_score) && 
      (jack_score < seven_score) && 
      (jack_score < eight_score) && 
      (jack_score < nine_score) && 
      (jack_score < ten_score) && 
      (jack_score < queen_score) && 
      (jack_score < king_score) && 
      (jack_score < ace_score)) begin 
        output_rank_score = jack_score;
        output_rank_map = jack_map;
  end
  if ((queen_score < two_score) && 
      (queen_score < three_score) && 
      (queen_score < four_score) && 
      (queen_score < five_score) && 
      (queen_score < six_score) && 
      (queen_score < seven_score) && 
      (queen_score < eight_score) && 
      (queen_score < nine_score) && 
      (queen_score < ten_score) && 
      (queen_score < jack_score) && 
      (queen_score < king_score) && 
      (queen_score < ace_score)) begin 
        output_rank_score = queen_score;
        output_rank_map = queen_map;
  end
  if ((king_score < two_score) && 
      (king_score < three_score) && 
      (king_score < four_score) && 
      (king_score < five_score) && 
      (king_score < six_score) && 
      (king_score < seven_score) && 
      (king_score < eight_score) && 
      (king_score < nine_score) && 
      (king_score < ten_score) && 
      (king_score < jack_score) && 
      (king_score < queen_score) && 
      (king_score < ace_score)) begin 
        output_rank_score = king_score;
        output_rank_map = king_map;
  end
  if ((ace_score < two_score) && 
      (ace_score < three_score) && 
      (ace_score < four_score) && 
      (ace_score < five_score) && 
      (ace_score < six_score) && 
      (ace_score < seven_score) && 
      (ace_score < eight_score) && 
      (ace_score < nine_score) && 
      (ace_score < ten_score) && 
      (ace_score < jack_score) && 
      (ace_score < queen_score) && 
      (ace_score < king_score)) begin 
        output_rank_score = ace_score;
        output_rank_map = ace_map;
  end
end

always_comb begin : suit_ranking
  if ((club_score < spade_score) && 
      (club_score < heart_score) && 
      (club_score < diamond_score)) begin 
        output_suit_score = club_score;
        output_suit_map = club_map;
  end
  if ((spade_score < club_score) && 
      (spade_score < heart_score) && 
      (spade_score < diamond_score)) begin 
        output_suit_score = spade_score;
        output_suit_map = spade_map;
  end
  if ((heart_score < spade_score) && 
      (heart_score < club_score) && 
      (heart_score < diamond_score)) begin 
        output_suit_score = heart_score;
        output_suit_map = heart_map;
  end
  if ((diamond_score < spade_score) && 
      (diamond_score < heart_score) && 
      (diamond_score < club_score)) begin 
        output_suit_score = diamond_score;
        output_suit_map = diamond_map;
  end
end 

endmodule

`default_nettype wire
