`timescale 1ns / 1ps
`default_nettype none

module scale(
  input wire [1:0] scale_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [15:0] frame_buff_in,
  output logic [15:0] cam_out
);

  always_comb begin 
    if (scale_in == 2'b00) begin 
      if (hcount_in >= 0 && hcount_in <= 239 && vcount_in >= 0 && vcount_in <= 319) begin 
        cam_out = frame_buff_in;
      end else begin 
        cam_out = 16'h0000;
      end 
    end 
    if (scale_in == 2'b01) begin 
      if (hcount_in >= 0 && hcount_in <= 479 && vcount_in >= 0 && vcount_in <= 639) begin 
        cam_out = frame_buff_in;
      end else begin 
        cam_out = 16'h0000;
      end
    end
    if (scale_in == 2'b10) begin 
      if (hcount_in >= 0 && hcount_in <= 639 && vcount_in >= 0 && vcount_in <= 852) begin 
        cam_out = frame_buff_in;
      end else begin 
        cam_out = 16'h0000;
      end
    end
    if (scale_in == 2'b11) begin 
    end
  end 
endmodule


`default_nettype wire
