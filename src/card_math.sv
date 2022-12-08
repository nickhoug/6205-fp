`timescale 1ns / 1ps
`default_nettype none

module card_math #(
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

    input wire [$clog2(WIDTH) - 1: 0] right_edge, 
    input wire [$clog2(WIDTH) - 1: 0] left_edge,
    input wire [$clog2(HEIGHT) - 1: 0] top_edge,
    input wire [$clog2(HEIGHT) - 1: 0] bot_edge,
    
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

logic [1119:0] two   = 1120'hfffffffffffffffffffffffffffffffffffffffffffff0fffff801ffff000fffe0007ffe1f83ffc3fe1ffc7fe1ffc7ff1ffc7ff1ffc7ff1fffffe1fffffe1fffffc3fffff83fffff07ffffe0fffff81fffff03ffffe0fffffc1fffff83fffff07fffff0fffffe1fffffe1ff1ffe3ff1ffc3ff1ffc3ff1ffc0001ffc0001ffc0001ffffffffffffffffffffff;
logic [1119:0] three = 1120'hffffffffffffffffffffffffffffffffffffffffffffffffffc0007ffc0007ffc0007ffcff0fffcff1fffcfe3fffffc3fffff87fffff0fffffe0fffffc01ffff800ffff8787fffffc3fffffe3ffffff1ffffff1ffffff1ffffff1ffffff1ffffff1ffdfff1ff8fff1ff8ffe3ffc7fc3ffe1f07ffe000ffff801ffffc07ffffffffffffffffffffffffffffff;
logic [1119:0] four  = 1120'hfffffffffffffffffffffffffffffffffffffffffffffffffffffcffffff8ffffff8ffffff0fffffe0fffffc0fffffc0fffff80fffff08fffff18ffffe38ffffc38ffff878ffff8f8ffff0f8fffe1f8fffe3f8fffc7f8fff87f8fff87f0fff00000ff00000ffe0001fffff8ffffff8ffffff8ffffff8fffffc03ffffc03ffffe07ffffffffffffffffffffff;
logic [1119:0] five  = 1120'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe000fffe000fffc3fffffc7fffffc7fffffc7fffffc60ffffc003fffc000fffc1f07ffc3f87ffc7fe3fffffe3ffffff1ffffff1ffffff1ffffff1ffffff1ffffff1ffffff1ffdffe1ff8ffe3ff8ffc3ffc7f87ffc0c0fffe001ffff803ffffffffffffffffffffffffffffff;
logic [1119:0] six   = 1120'hfffffffffffffffffffffffffffffffffffffffffffffffffffffffffff07ffff801ffff0007ffe0f87ffc3fe3ffc7ff7ff87fffff8ffffff8f8ffff8c03fff0000fff00007ff01f87ff07fc3ff0ffe3ff0fff1ff1fff1ff1fff1ff1fff1ff1fff1ff1fff1ff9fff1ff8fff1ff8ffe3ff87fe3ffc3f87ffe0407fff000ffff803fffffdfffffffffffffffff;
logic [1119:0] seven = 1120'hfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff80003ff80001ff80000ff8fff0ff8ffe1ff8ffc3fffffc7fffff87fffff0ffffff0fffffe1fffffe1fffffe3fffffc3fffffc7fffff87fffff8ffffff8ffffff1ffffff1ffffff1fffffe3fffffe3fffffe3fffffc3fffffc7fffffc7ffffffffffffffffffffffff;
logic [1119:0] eight = 1120'hfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe1fffff803fffe0c1fffc7f8fffcffcfffcffc7ff8ffe7ff8ffe7ffcffc7ffc7fc7ffe3f8ffff001ffff001fffe0f0fffc7fc7ff8ffe3ff8fff3ff9fff3ff1fff1ff9fff1ff9fff3ff8ffe3ffc7fe7ffc3f87ffe000ffff803fffffffffffffffffffffffffffffffffffff;
logic [1119:0] nine  = 1120'hfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff803ffff001fffe0e0fffc3f87ffc7fc7ffc7fc3ff87fe3ff8ffe3ff8ffe3ff8ffe3ff87fe3ffc7fe3ffc7fe3ffc3fc3ffe1f03fff0003fff8023fffc0e3fffffe3fffffc3fffffc7ffc7f87ffc7f0fffc1e0fffe001ffff807ffffe1fffffffffffffffffffffffffffffff;
logic [1119:0] ten   = 1120'hfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9fc0fff8f803ff8f003ff9f1f1ff9e3f1ff9e3f9ff9e3f9ff9e3f9ff8e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f9ff9e3f1ff9f1f1ff9f003ff9f807ff9fc0fffffffffffffffffffffff;
logic [1119:0] jack  = 1120'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbfffffe001fffe003ffffe0fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1fffffe1ff87fe1ff87fe1ff87fe1ff87fc1ff83fc3ffc0e03ffe000ffff801fffffbffffffffffffffffffffffff;
logic [1119:0] queen = 1120'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0fffff801ffff000fffe0f0fffe1f07ffe3f87ffe3f87ffc3f87ffc3f87ffc3fc7ffc3fc7ffc3fc7ffc3fc7ffc3fc7ff83fc7ff01fc7ff007c7ff801c7ffc00c7ffc3007ffc3c07ffe3e0fffe1f0fffe0000fff0000fffc070fffffffffffffffffffffffffffff;
logic [1119:0] king  = 1120'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00e007f00e007fc3fc3ffc3f87ffc3f0fffc3e1fffc3c1fffc3c3fffc387fffc30ffffc20ffffc007fffc007fffc043fffc0c3fffc1e1fffc3e1fffc3f0fffc3f8fffc3f87ffc3fc7ffc3fc3ff00f00fe006007f00e007ffffffffffffffffffffffffffff;
logic [1119:0] ace   = 1120'hfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe1fffffe1fffffe1fffffe1fffffe1fffffc0fffffc0fffffc0fffffccfffffcc7ffff8c7ffff8c7ffff8c7ffff8e7ffff9e3ffff9e3ffff1e3ffff1f3ffff1f3ffff001ffff001fffe001fffe3f1fffe3f8fffe3f8fffe7f8fff81e03ff01e03ff81f07fffffffffffffff;

logic [811:0] spade   = 812'hfffffffffffffffffffffffffffffff9ffffff0fffffe07ffffc03ffff801ffff000fffe0007ffc0003ffc0003ff80001ff00000fe000007e000007e000003e000003e009003e009003e009007f01880ffc30e3ffff0ffffff07ffffe03ffffffffffffffff;
logic [811:0] diamond = 812'hfffffffffffffffffffffffffffffffbffffff1ffffff0fffffe07ffffc07ffff803ffff001fffe000fffc0007ff80003ff00001ff80003ffc0007ffe000ffff001ffff801ffffc03ffffe07ffffe0ffffff0ffffff9fffffffffffffffffffffffffffffff;
logic [811:0] heart   = 812'hffffffffffffffffffffffe1f87ff80e03ff80601ff00000ff00000ff00000ff00000ff00000ff00000ff00000ff80001ff80001ffc0003ffc0007ffe0007fff000ffff001ffff803ffffc03ffffe07ffffe0ffffff1ffffff9ffffffffffffffffffffffff;
logic [811:0] club    = 812'hffffffffffffffffffffffffffffffe07ffffc03ffff801ffff801ffff800ffff801ffff801ffffc01fffc6023ff00000fe000007e000003e000003e000003e001007f009007f81980ffc78e3ffff8ffffff07fffff07ffffffffffffffffffffffffffffff;

logic [1119:0] rank; 
logic [811:0] suit;

logic [10:0] output_rank_score; 
logic [9:0] output_suit_score;

logic [3:0] output_rank_map; 
logic [3:0] output_suit_map; 

logic [10:0] two_score; 
logic [10:0] three_score;
logic [10:0] four_score;
logic [10:0] five_score;
logic [10:0] six_score;
logic [10:0] seven_score;
logic [10:0] eight_score;
logic [10:0] nine_score;
logic [10:0] ten_score;
logic [10:0] jack_score;
logic [10:0] queen_score;
logic [10:0] king_score;
logic [10:0] ace_score;

logic [9:0] spade_score;
logic [9:0] diamond_score;
logic [9:0] heart_score;
logic [9:0] club_score;

logic [1119:0] two_score_array; 
logic [1119:0] three_score_array;
logic [1119:0] four_score_array;
logic [1119:0] five_score_array;
logic [1119:0] six_score_array;
logic [1119:0] seven_score_array;
logic [1119:0] eight_score_array;
logic [1119:0] nine_score_array;
logic [1119:0] ten_score_array;
logic [1119:0] jack_score_array;
logic [1119:0] queen_score_array;
logic [1119:0] king_score_array;
logic [1119:0] ace_score_array;

logic [811:0] spade_score_array;
logic [811:0] diamond_score_array;
logic [811:0] heart_score_array;
logic [811:0] club_score_array;

logic [10:0] index_rank; 
logic [9:0] index_suit; 

assign two_score_array   = two ^ rank; 
assign three_score_array = three ^ rank;
assign four_score_array  = four ^ rank;
assign five_score_array  = five ^ rank;
assign six_score_array   = six ^ rank;
assign seven_score_array = seven ^ rank;
assign eight_score_array = eight ^ rank;
assign nine_score_array  = nine ^ rank;
assign ten_score_array   = ten ^ rank;
assign jack_score_array  = jack ^ rank;
assign queen_score_array = queen ^ rank;
assign king_score_array  = king ^ rank;
assign ace_score_array   = ace ^ rank;

assign spade_score_array       = spade ^ suit; 
assign diamond_score_array     = diamond ^ suit; 
assign heart_score_array       = heart ^ suit; 
assign club_score_array        = club ^ suit; 

assign card_map = {output_rank_map, output_rank_map};
assign rank_score = 100 - (output_rank_score * 100) / (corner_width * rank_height); //should be percentage where 100% is perfect
assign suit_score = 100 - (output_suit_score * 100) / (corner_width * suit_height);

always_ff @(posedge clk) begin : update
  if ((hcount > (left_edge + 4)) && (hcount <= (left_edge + 4 + corner_width)) && (vcount > top_edge) && (vcount < (top_edge + rank_height))) begin 
    rank[index_rank] <= mask;
    index_rank <= index_rank - 1; 
  end 
  if ((hcount > (left_edge + 4)) && (hcount <= (left_edge + 4 + corner_width)) && (vcount >= (top_edge + rank_height)) && (vcount < (top_edge + rank_height + suit_height))) begin 
    suit[index_suit] <= mask;
    index_suit <= index_suit - 1;
  end
  if ((hcount > (left_edge + 4 + corner_width)) && (vcount > (top_edge + rank_height + suit_height))) begin 
    index_rank <= 11'd1119; 
    index_suit <= 10'd811;
  end 
  if (rst) begin 
    index_rank <= 11'd1119; 
    index_suit <= 10'd811;
    rank <= 0; 
    suit <= 0; 
  end 
end

always_comb begin : scoring //higher score is bad -> need to find the lowest!
  for (integer i = 0; i < 1120; i = i + 1) begin 
    two_score = two_score + two_score_array[i];
    three_score = three_score + three_score_array[i];
    four_score = four_score + four_score_array[i];
    five_score = five_score + five_score_array[i];
    six_score = six_score + six_score_array[i];
    seven_score = seven_score + seven_score_array[i];
    eight_score = eight_score + eight_score_array[i];
    nine_score = nine_score + nine_score_array[i];
    ten_score = ten_score + ten_score_array[i];
    jack_score = jack_score + jack_score_array[i];
    queen_score = queen_score + queen_score_array[i];
    king_score = king_score + king_score_array[i];
    ace_score = ace_score + ace_score_array[i]; 
  end 
  for (integer j = 0; j < 812; j = j + 1) begin
    spade_score = spade_score + spade_score_array[j]; 
    diamond_score = diamond_score + diamond_score_array[j];
    heart_score = heart_score + heart_score_array[j];
    club_score = club_score + club_score_array[j];
  end
end

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
