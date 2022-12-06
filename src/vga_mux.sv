module vga_mux (
  input wire [3:0] sel_in, //regular video
  input wire [11:0] camera_pixel_in,
  input wire thresholded_pixel_in,
  input wire crosshair_in,
  input wire edge_in, 
  output logic [11:0] pixel_out
);

  /*
  00: normal camera out
  01: channel image (in grayscale)
  10: (thresholded channel image b/w)
  11: y channel with magenta mask

  upper bits:
  00: nothing:
  01: crosshair
  10: sprite on top
  11: nothing (magenta test color)
  */

  logic [11:0] l_1;
  logic [11:0] l_2;
  logic [11:0] l_3;

  always_comb begin
    case (sel_in[1:0])
      2'b00: l_1 = camera_pixel_in; //normal video
      2'b10: l_1 = (thresholded_pixel_in !=0)?12'hFFF:12'h000; //mask
    endcase
  end

  always_comb begin
    case (sel_in[2])
      1'b0: l_2 = l_1;
      1'b1: l_2 = crosshair_in ? 12'h0F0:l_1; //crosshair
    endcase
  end

  always_comb begin
    case (sel_in[3])
      1'b0: l_3 = l_2;
      1'b1: l_3 = edge_in ? 12'h0F0:l_2; //edges
    endcase
  end
  
  assign pixel_out = l_3;
endmodule
