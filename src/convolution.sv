`timescale 1ns / 1ps
`default_nettype none

module convolution #(
    parameter K_SELECT=0)(
    input wire clk_in,
    input wire rst_in,
    input wire [2:0][15:0] data_in,
    input wire [7:0] hcount_in,
    input wire [8:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [7:0] hcount_out,
    output logic [8:0] vcount_out,
    output logic [15:0] line_out
    );

    kernels #(.K_SELECT(K_SELECT)) kernel (.rst_in(rst_in),
                                            .coeffs(coeffs),
                                            .shift(shift));

    /*********************************************************************************

                                        |            |
                             top_row[2] | top_row[1] | top_row[0]   <----- data_in[2]
                                        |            | 
                            --------------------------------------
                                        |            |
                             mid_row[2] | mid_row[1] | mid_row[0]   <----- data_in[1]
                                        |            |
                            --------------------------------------
                                        |            |
                             bot_row[2] | bot_row[1] | bot_row[0]   <----- data_in[0]
                                        |            |
 

                     
                                       |               |
                         hcount_pipe_2 | hcount_pipe_1 | hcount_pipe_0   <----- hcount_in
                                       |               |
                            --------------------------------------
                                       |               |
                         vcount_pipe_2 | vcount_pipe_1 | vcount_pipe_0   <----- vcount_in
                                       |               |
                

    **********************************************************************************/

    logic [7:0] hcount_pipe_0;
    logic [7:0] hcount_pipe_1;
    logic [7:0] hcount_pipe_2;
    logic [7:0] hcount_pipe_3;

    logic [8:0] vcount_pipe_0;
    logic [8:0] vcount_pipe_1;
    logic [8:0] vcount_pipe_2;
    logic [8:0] vcount_pipe_3;
    
    logic [2:0][15:0] top_row; 
    logic [2:0][15:0] mid_row; 
    logic [2:0][15:0] bot_row; 

    logic data_valid_pipe_0; 
    logic data_valid_pipe_1; 
    logic data_valid_pipe_2;

    logic signed [15:0] red; 
    logic signed [15:0] green; 
    logic signed [15:0] blue; 

    logic [4:0] r;
    logic [5:0] g;
    logic [4:0] b; 

    logic signed [2:0][2:0][7:0] coeffs; 
    logic signed [7:0] shift; 

    always_ff @(posedge clk_in) begin: MATH
        
        if (rst_in == 1'b1) begin
            top_row <= 0; 
            mid_row <= 0; 
            bot_row <= 0;
            red <= 0; 
            green <= 0; 
            blue <= 0; 
            line_out <= 0; 
            data_valid_out <= 0; 
        end 

        if (data_valid_in == 1'b1 && vcount_in >= 2 && vcount_in <= 318 && hcount_in >= 1 && hcount_in <= 239) begin 
            hcount_pipe_0 <= hcount_in; 
            hcount_pipe_1 <= hcount_pipe_0;
            hcount_pipe_2 <= hcount_pipe_1;
            hcount_pipe_3 <= hcount_pipe_2;
            hcount_out <= hcount_pipe_3;

            vcount_pipe_0 <= vcount_in; 
            vcount_pipe_1 <= vcount_pipe_0;
            vcount_pipe_2 <= vcount_pipe_1;
            vcount_pipe_3 <= vcount_pipe_2;
            vcount_out <= vcount_pipe_3 - 2;

            top_row[0] <= data_in[2]; 
            top_row[1] <= top_row[0];
            top_row[2] <= top_row[1]; 

            mid_row[0] <= data_in[1]; 
            mid_row[1] <= mid_row[0];
            mid_row[2] <= mid_row[1]; 

            bot_row[0] <= data_in[0]; 
            bot_row[1] <= bot_row[0];
            bot_row[2] <= bot_row[1]; 

            data_valid_pipe_0 <= 1'b1; 
        end 

        if (data_valid_in == 1'b0) begin 
            data_valid_pipe_0 <= 1'b0; 
        end 

        data_valid_pipe_1 <= data_valid_pipe_0; 
        data_valid_pipe_2 <= data_valid_pipe_1;
        data_valid_out <= data_valid_pipe_2; 
        
        red <=  (($signed({1'b0, top_row[2][15:11]}) * $signed(coeffs[0][0])) + 
                 ($signed({1'b0, top_row[1][15:11]}) * $signed(coeffs[0][1])) + 
                 ($signed({1'b0, top_row[0][15:11]}) * $signed(coeffs[0][2])) + 
                 ($signed({1'b0, mid_row[2][15:11]}) * $signed(coeffs[1][0])) + 
                 ($signed({1'b0, mid_row[1][15:11]}) * $signed(coeffs[1][1])) + 
                 ($signed({1'b0, mid_row[0][15:11]}) * $signed(coeffs[1][2]))+ 
                 ($signed({1'b0, bot_row[2][15:11]}) * $signed(coeffs[2][0])) + 
                 ($signed({1'b0, bot_row[1][15:11]}) * $signed(coeffs[2][1])) + 
                 ($signed({1'b0, bot_row[0][15:11]}) * $signed(coeffs[2][2]))) >>> shift; 

        green <= (($signed({1'b0, top_row[2][10:5]}) * $signed(coeffs[0][0])) + 
                  ($signed({1'b0, top_row[1][10:5]}) * $signed(coeffs[0][1])) + 
                  ($signed({1'b0, top_row[0][10:5]}) * $signed(coeffs[0][2])) + 
                  ($signed({1'b0, mid_row[2][10:5]}) * $signed(coeffs[1][0])) + 
                  ($signed({1'b0, mid_row[1][10:5]}) * $signed(coeffs[1][1])) + 
                  ($signed({1'b0, mid_row[0][10:5]}) * $signed(coeffs[1][2])) + 
                  ($signed({1'b0, bot_row[2][10:5]}) * $signed(coeffs[2][0])) + 
                  ($signed({1'b0, bot_row[1][10:5]}) * $signed(coeffs[2][1])) + 
                  ($signed({1'b0, bot_row[0][10:5]}) * $signed(coeffs[2][2]))) >>> shift; 

        blue <=  (($signed({1'b0, top_row[2][4:0]}) * $signed(coeffs[0][0])) + 
                  ($signed({1'b0, top_row[1][4:0]}) * $signed(coeffs[0][1])) + 
                  ($signed({1'b0, top_row[0][4:0]}) * $signed(coeffs[0][2])) + 
                  ($signed({1'b0, mid_row[2][4:0]}) * $signed(coeffs[1][0])) + 
                  ($signed({1'b0, mid_row[1][4:0]}) * $signed(coeffs[1][1])) + 
                  ($signed({1'b0, mid_row[0][4:0]}) * $signed(coeffs[1][2])) + 
                  ($signed({1'b0, bot_row[2][4:0]}) * $signed(coeffs[2][0])) + 
                  ($signed({1'b0, bot_row[1][4:0]}) * $signed(coeffs[2][1])) + 
                  ($signed({1'b0, bot_row[0][4:0]}) * $signed(coeffs[2][2]))) >>> shift;
        
        r <= red < 0 ? 0 : red[4:0];
        g <= green < 0 ? 0 : green[5:0];
        b <= blue < 0 ? 0 : blue[4:0];

        line_out <= {r, g, b};

    end 


endmodule

`default_nettype wire
