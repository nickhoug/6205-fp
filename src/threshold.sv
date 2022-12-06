module threshold(

  input wire [4:0] r_in, 
  input wire [5:0] g_in, 
  input wire [4:0] b_in,
 
  input wire [7:0] mask,
  output logic mask_out

);

  assign mask_out = ({r_in, 3'b000} + {g_in, 2'b00} + {b_in, 3'b000}) < mask * 3 ? 0 : 1; //max value = 1011101100

endmodule

