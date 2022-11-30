`default_nettype none
`timescale 1ns / 1ps

`define HEIGHT 320
`define WIDTH 240
`define SIZE `HEIGHT * `WIDTH

/****************************COMMANDS******************************************

python3 lab-bc.py -o obj

openFPGALoader -b arty_a7_100t obj/out.bit

********************************************************************************/

module top_level (
    input wire clk_100mhz, //clock @ 100 mhz
    input wire btnc, //btnc (used for reset)
    input wire [7:0] ja, //lower 8 bits of data from camera
    input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)

    output logic jbclk,  //signal we provide to camera
    output logic jblock, //signal for resetting camera
    output logic [15:0] led
    //output logic ca, cb, cc, cd, ce, cf, cg,
    //output logic [7:0] an
);

    //system reset switch linking
    logic sys_rst; //global system reset
    assign sys_rst = btnc; //just done to make sys_rst more obvious

    /* Video Pipeline */
    logic clk_65mhz; //65 MHz clock line

    //Generate 65 MHz:
    clk_wiz_lab3 clk_gen(
                        .clk_in1(clk_100mhz),
                        .clk_out1(clk_65mhz)); //after frame buffer everything on clk_65mhz


    //camera module: (see datasheet)
    logic cam_clk_buff, cam_clk_in; //returning camera clock
    logic vsync_buff, vsync_in; //vsync signals from camera
    logic href_buff, href_in; //href signals from camera
    logic [7:0] pixel_buff, pixel_in; //pixel lines from camera
    logic [15:0] cam_pixel; //16 bit 565 RGB image from camera
    logic valid_pixel; //indicates valid pixel from camera
    logic frame_done; //indicates completion of frame from camera

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

    //rotate module:
    logic valid_pixel_rotate;  //indicates valid rotated pixel
    logic [15:0] pixel_rotate; //rotated 565 rotate pixel
    logic [16:0] pixel_addr_in; //address of rotated pixel in 240X320 memory

    //Rotates Image to render correctly (pi/2 CCW rotate):
    rotate rotate_m (
                    .cam_clk_in(cam_clk_in),
                    .valid_pixel_in(valid_pixel),
                    .pixel_in(cam_pixel),
                    .valid_pixel_out(valid_pixel_rotate),
                    .pixel_out(pixel_rotate),
                    .frame_done_in(frame_done),
                    .pixel_addr_in(pixel_addr_in));

    //values  of frame buffer:
    logic [16:0] pixel_addr_out; //
    logic [15:0] frame_buff; //output of scale module 

    //Two Clock Frame Buffer:
    //Data written on 16.67 MHz (From camera)
    //Data read on 65 MHz (start of video pipeline information)
    //Latency is 2 cycles.
    xilinx_true_dual_port_read_first_2_clock_ram #(
                                                .RAM_WIDTH(16),
                                                .RAM_DEPTH(`SIZE))
                                                RGB_frame_buffer (
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

    threshold thresholder (
                        .clk_in(clk_65mhz), //system clock
                        .rst_in(sys_rst), //system reset

                        .hcount_in(hcount_in), //current hcount being read
                        .vcount_in(vcount_in), //current vcount being read
                        .data_valid_in(threshold_valid_in), 
                        .pixel_data_in(ram_out), //incoming pixel

                        .data_valid_out(threshold_valid_out),
                        .pixel_data_out(threshold_out), //output pixels of data (blah make this packed)
                        .hcount_out(hcount_out), //current hcount being read
                        .vcount_out(vcount_out) //current vcount being read
                        );

    center_of_mass COM (
                        .clk_in(clk_65mhz),
                        .rst_in(sys_rst),
                        .x_in(hcount_out),
                        .y_in(vcount_out),
                        .valid_in(com_valid_in),
                        .tabulate_in(com_tabulate),
                        .x_out(com_x),
                        .y_out(com_y),
                        .valid_out(com_valid_out)
                        );

endmodule

`default_nettype wire