`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //clock @ 100 mhz
  input wire [15:0] sw, //switches
  input wire btnc, //btnc (used for reset)

  input wire [7:0] ja, //lower 8 bits of data from camera
  input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
  output logic jbclk,  //signal we provide to camera
  output logic jblock, //signal for resetting camera

  output logic [15:0] led, //just here for the funs

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs,
  output logic [7:0] an,
  output logic caa,cab,cac,cad,cae,caf,cag

  );

  
  logic sys_rst; 
  assign sys_rst = btnc; 

  assign led = sw; 

  /* Video Pipeline */
  logic clk_65mhz; //65 MHz clock line

  //vga module generation signals:
  logic [10:0] hcount;    // pixel on current line
  logic [9:0] vcount;     // line number
  logic hsync, vsync, blank; //control signals for vga
  logic hsync_t, vsync_t, blank_t; //control signals out of transform


  //camera module: (see datasheet)
  logic cam_clk_buff, cam_clk_in; //returning camera clock
  logic vsync_buff, vsync_in; //vsync signals from camera
  logic href_buff, href_in; //href signals from camera
  logic [7:0] pixel_buff, pixel_in; //pixel lines from camera
  logic [15:0] cam_pixel; //16 bit 565 RGB image from camera
  logic valid_pixel; //indicates valid pixel from camera
  logic frame_done; //indicates completion of frame from camera

  //rotate module:
  logic valid_pixel_rotate;  //indicates valid rotated pixel
  logic [15:0] pixel_rotate; //rotated 565 rotate pixel
  logic [16:0] pixel_addr_in; //address of rotated pixel in 240X320 memory

  //values  of frame buffer:
  logic [16:0] pixel_addr_out; //
  logic [15:0] frame_buff; //output of scale module

  // output of scale module
  logic [15:0] full_pixel;//mirrored and scaled 565 pixel

  //output of rgb to ycrcb conversion:
  logic [9:0] y, cr, cb; //ycrcb conversion of full pixel

  //output of threshold module:
  logic mask; //Whether or not thresholded pixel is 1 or 0

  //Center of Mass variables
  logic [10:0] x_com, x_com_calc; //long term x_com and output from module, resp
  logic [9:0] y_com, y_com_calc; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...
  //using x_com_calc and y_com_calc values

  //Crosshair value hot when hcount,vcount== (x_com, y_com)
  logic crosshair;

  logic edges; 

  logic zoom; 

  logic [10:0] x_shift;  
  logic [9:0] y_shift;   

  //vga_mux output:
  logic [11:0] mux_pixel; //final 12 bit information from vga multiplexer
  //goes right into RGB of output for video render


  /************************************PIPELINE*******************************************/

  logic [10:0] hcount_pipe [7-1:0];
  logic [9:0] vcount_pipe [7-1:0];
  logic blank_pipe [7-1:0];

  logic crosshair_pipe [4-1:0];

  logic [15:0] full_pixel_pipe [3-1:0];

  logic hsync_pipe [8-1:0];
  logic vsync_pipe [8-1:0];

  logic [9:0] top_edge_calc; 
  logic [9:0] bot_edge_calc; 
  logic [10:0] left_edge_calc;
  logic [10:0] right_edge_calc;

  logic [9:0] top_edge; 
  logic [9:0] bot_edge; 
  logic [10:0] left_edge;
  logic [10:0] right_edge;

  logic find_corners_flag; 
  logic find_corners_valid;

  logic [$clog2(640*480) - 1:0] addr_corners; 

  logic pixel_data_corners; 

  always_ff @(posedge clk_65mhz)begin
    hcount_pipe[0] <= hcount;
    vcount_pipe[0] <= vcount;
    crosshair_pipe[0] <= crosshair;
    full_pixel_pipe[0] <= full_pixel;
    hsync_pipe[0] <= hsync;
    vsync_pipe[0] <= vsync; 
    blank_pipe[0] <= blank;

    for (int i = 1; i < 7; i = i + 1) begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
      blank_pipe[i] <= blank_pipe[i-1];
    end

    for (int j = 1; j < 4; j = j + 1) begin
      crosshair_pipe[j] <= crosshair_pipe[j-1];
    end 

    for (int k = 1; k < 3; k = k + 1) begin 
      full_pixel_pipe[k] <= full_pixel_pipe[k-1];
    end 

    for (int l = 1; l < 8; l = l + 1) begin 
      hsync_pipe[l] <= hsync_pipe[l-1];
      vsync_pipe[l] <= vsync_pipe[l-1];
    end 

  end

  /************************************PIPELINE*******************************************/

  //Generate 65 MHz:
  clk_wiz_lab3 clk_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz

  //Generate VGA timing signals:
  vga vga_gen(
    .pixel_clk_in(clk_65mhz),
    .hcount_out(hcount),
    .vcount_out(vcount),
    .hsync_out(hsync),
    .vsync_out(vsync),
    .blank_out(blank));

  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.
  always_ff @(posedge clk_65mhz) begin
    cam_clk_buff <= jb[0]; //sync camera
    cam_clk_in <= cam_clk_buff;
    vsync_buff <= jb[1]; //sync vsync signal
    vsync_in <= vsync_buff;
    href_buff <= jb[2]; //sync href signal
    href_in <= href_buff;
    pixel_buff <= ja; //sync pixels
    pixel_in <= pixel_buff;
  end

  //Controls and Processes Camera information
  camera camera_m(
    //signal generate to camera:
    .clk_65mhz(clk_65mhz),
    .jbclk(jbclk),
    .jblock(jblock),
    //returned information from camera:
    .cam_clk_in(cam_clk_in),
    .vsync_in(vsync_in),
    .href_in(href_in),
    .pixel_in(pixel_in),
    //output framed info from camera for processing:
    .pixel_out(cam_pixel),
    .pixel_valid_out(valid_pixel),
    .frame_done_out(frame_done));

  //Rotates Image to render correctly (pi/2 CCW rotate):
  rotate rotate_m (
    .cam_clk_in(cam_clk_in),
    .valid_pixel_in(valid_pixel),
    .pixel_in(cam_pixel),
    .valid_pixel_out(valid_pixel_rotate),
    .pixel_out(pixel_rotate),
    .frame_done_in(frame_done),
    .pixel_addr_in(pixel_addr_in));

  //Latency: 2
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(16),
    .RAM_DEPTH(320*240))
    frame_buffer (
    //Write Side (16.67MHz)
    .addra(pixel_addr_in),
    .clka(cam_clk_in),
    .wea(valid_pixel_rotate),
    .dina(pixel_rotate),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(),
    //Read Side (65 MHz)
    .addrb(pixel_addr_out),
    .dinb(16'b0),
    .clkb(clk_65mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(frame_buff)
  );

  //latency: 2 cycles
  mirror mirror_m(
    .clk_in(clk_65mhz),
    .mirror_in(sw[2]),
    .scale_in(sw[1:0]),
    .hcount_in(hcount), //
    .vcount_in(vcount),
    .pixel_addr_out(pixel_addr_out)
  );

  //Latency: 0
  scale scale_m(
    .scale_in(sw[1:0]),
    .hcount_in(hcount_pipe[4]),
    .vcount_in(vcount_pipe[4]),
    .frame_buff_in(frame_buff),
    .cam_out(full_pixel)
    );

  //Latency: 0
  threshold grayscale (
     .r_in(full_pixel[15:11]), //TODO: needs to use pipelined signal (PS5) (DONE)
     .g_in(full_pixel[10:5]),  //TODO: needs to use pipelined signal (PS5) (DONE)
     .b_in(full_pixel[4:0]),   //TODO: needs to use pipelined signal (PS5) (DONE)
     .mask(sw[15:8]),
     .mask_out(mask));

  //Latency: 2
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(1),
    .RAM_DEPTH(640*480))
    mask_bram (
    //Write Side (65 MHz)
    .addra(hcount_pipe[4] + vcount_pipe[4]*480),
    .dina(mask),
    .clka(clk_65mhz),
    .wea((hcount_pipe[4] < 480 && vcount_pipe[4] < 640)),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(),
    //Read Side (65 MHz)
    .addrb(addr_corners),
    .dinb(16'b0),
    .clkb(clk_65mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(pixel_data_corners)
  );

  //Center of Mass:
  center_of_mass com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_pipe[4]),  //TODO: needs to use pipelined signal! (PS3) (DONE)
    .y_in(vcount_pipe[4]), //TODO: needs to use pipelined signal! (PS3) (DONE)
    .valid_in(mask),
    .tabulate_in((hcount==0 && vcount==0)),
    .x_out(x_com_calc),
    .y_out(y_com_calc),
    .valid_out(new_com));

  //Edge calculation
  edges #(
    .HEIGHT(640), 
    .WIDTH(480))
    corner_finder (
    .clk_in(clk_65mhz), //system clock
    .rst_in(sys_rst), //system reset

    .find_corners_flag(find_corners_flag),
    .x_center(x_com), 
    .y_center(y_com), 
    .pixel_data_in(pixel_data_corners),  

    .addr_out(addr_corners), 

    .data_valid_out(find_corners_valid),
    .right_edge(right_edge_calc), 
    .left_edge(left_edge_calc),
    .top_edge(top_edge_calc),
    .bot_edge(bot_edge_calc)
  );

  //update center of mass x_com, y_com based on new_com signal
  always_ff @(posedge clk_65mhz)begin
    if (sys_rst)begin
      x_com <= 0;
      y_com <= 0;
    end if(new_com)begin
      x_com <= x_com_calc;
      y_com <= y_com_calc;
      find_corners_flag <= 1; 
    end if (find_corners_flag) begin 
      find_corners_flag <= 0;
    end 
  end

  always_ff @(posedge clk_65mhz)begin
    if (sys_rst)begin
      left_edge <= 0; 
      right_edge <= 0; 
      top_edge <= 0; 
      bot_edge <= 0; 
    end if(find_corners_valid)begin
      left_edge <= left_edge_calc; 
      right_edge <= right_edge_calc; 
      top_edge <= top_edge_calc; 
      bot_edge <= bot_edge_calc; 
    end
  end

  seven_segment_controller display (
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),

    .suit(card_map[5:4]),  
    .rank(card_map[3:0]), 
    .suit_score(), 
    .rank_score(),

    .cat_out({cag, caf, cae, cad, cac, cab, caa}),
    .an_out(an)); 

  logic [10:0] two_score; 
  XOR_two two_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .two_score(two_score)
  );

  logic [10:0] three_score; 
  XOR_three three_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .three_score(three_score)
  );

  logic [10:0] four_score; 
  XOR_four four_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .four_score(four_score)
  );

  logic [10:0] five_score; 
  XOR_five five_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .five_score(five_score)
  );

  logic [10:0] six_score; 
  XOR_six six_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .six_score(six_score)
  );

  logic [10:0] seven_score; 
  XOR_seven seven_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .seven_score(seven_score)
  );

  logic [10:0] eight_score; 
  XOR_eight eight_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .eight_score(eight_score)
  );

  logic [10:0] nine_score; 
  XOR_nine nine_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .nine_score(nine_score)
  );

  logic [10:0] ten_score; 
  XOR_ten ten_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .ten_score(ten_score)
  );

  logic [10:0] jack_score; 
  XOR_jack jack_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .jack_score(jack_score)
  );

  logic [10:0] queen_score; 
  XOR_queen queen_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .queen_score(queen_score)
  );

  logic [10:0] king_score; 
  XOR_king king_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .king_score(king_score)
  );

  logic [10:0] ace_score; 
  XOR_ace ace_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .ace_score(ace_score)
  );

  logic [9:0] club_score; 
  XOR_club club_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .club_score(club_score)
  );

  logic [9:0] spade_score; 
  XOR_spade spade_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .spade_score(spade_score)
  );

  logic [9:0] heart_score; 
  XOR_heart heart_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .heart_score(heart_score)
  );

  logic [9:0] diamond_score; 
  XOR_diamond diamond_kernel (
    .clk(clk_65mhz), 
    .rst(sys_rst), 
    .hcount(hcount_pipe[4]), 
    .vcount(vcount_pipe[4]),
    .mask(mask), 

    .left_edge(left_edge), 
    .top_edge(top_edge), 

    .diamond_score(diamond_score)
  );


  comparator best_score_calculator (
    .two_score(two_score),
    .three_score(three_score),
    .four_score(four_score),
    .five_score(five_score),
    .six_score(six_score),
    .seven_score(seven_score),
    .eight_score(eight_score),
    .nine_score(nine_score),
    .ten_score(ten_score),
    .jack_score(jack_score),
    .queen_score(queen_score),
    .king_score(king_score),
    .ace_score(ace_score),

    .spade_score(spade_score), 
    .diamond_score(diamond_score),
    .heart_score(heart_score),
    .club_score(club_score),
    
    .rank_score(rank_score), 
    .suit_score(suit_score),
    .card_map(card_map));

  logic [6:0] rank_score; //left edge
  logic [6:0] suit_score; //middle
  logic [5:0] card_map; //right edge 

  //Create Crosshair, edges, zoom
  assign crosshair = ((vcount==y_com)||(hcount==x_com));
  assign edges = ((hcount==left_edge+4)||(hcount==right_edge+4)||(vcount==top_edge)||(vcount==bot_edge));
  assign zoom = ((hcount > left_edge+4) && (hcount <= left_edge+4+x_shift) && (vcount > top_edge) && (vcount < top_edge+ (y_shift*7/12))); 

  assign x_shift =  (right_edge - left_edge) / 7 ; 
  assign y_shift = (bot_edge - top_edge) / 4;

  vga_mux switch (
    .sel_in({sw[7:5], sw[3]}),
    .camera_pixel_in({full_pixel_pipe[2][15:12],full_pixel_pipe[2][10:7],full_pixel_pipe[2][4:1]}), //TODO: needs to use pipelined signal(PS5) (DONE)
    .thresholded_pixel_in(mask),
    .crosshair_in(crosshair_pipe[3]), //TODO: needs to use pipelined signal (PS4) (DONE)
    .edge_in(edges), 
    .zoom_in(zoom), 
    .pixel_out(mux_pixel));

  //Latency: 1
  always_ff @(posedge clk_65mhz)begin
    vga_r <= ~blank_pipe[6]?mux_pixel[11:8]:0; //TODO: needs to use pipelined signal (PS6) (DONE)
    vga_g <= ~blank_pipe[6]?mux_pixel[7:4]:0;  //TODO: needs to use pipelined signal (PS6) (DONE)
    vga_b <= ~blank_pipe[6]?mux_pixel[3:0]:0;  //TODO: needs to use pipelined signal (PS6) (DONE)
  end

  assign vga_hs = ~hsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)
  assign vga_vs = ~vsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)

endmodule




`default_nettype wire
