`timescale 1ns / 1ps
`default_nettype none

module buffer (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [7:0] hcount_in, //current hcount being read
    input wire [8:0] vcount_in, //current vcount being read
    input wire [15:0] pixel_data_in, //incoming pixel
    input wire data_valid_in, //incoming  valid data signal

    output logic [2:0][15:0] line_buffer_out, //output pixels of data (blah make this packed)
    output logic [7:0] hcount_out, //current hcount being read
    output logic [8:0] vcount_out, //current vcount being read
    output logic data_valid_out //valid data out signal
  );

  /*********************************************************************************
                                    
                                    2-PORT BRAM

                                 -----------------
                                |                 |
                 CLK ---------->|                 |<---------- CLK
               WR EN ---------->|                 |<---------- WR EN
                ADDR ---------->|       BRAM      |<---------- ADDR
   WR DATA (data in) ---------->|                 |<---------- WR DATA (data in)
  RD DATA (data out) <----------|                 |----------> RD DATA (data out)
                                |                 |
                                 -----------------

  **********************************************************************************/

  logic [3:0] write_enable = 4'b0001; 
  logic [8:0] vcount_in_old; 

  logic [3:0][15:0] data_out_read;
  logic [3:0][15:0] data_out_write;

  logic [7:0] hcount_out_1; 
  logic [7:0] hcount_out_2;

  logic [8:0] vcount_out_1; 
  logic [8:0] vcount_out_2; 

  logic data_valid_out_pipe_1; 
  logic data_valid_out_pipe_2; 

  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin
      xilinx_true_dual_port_read_first_1_clock_ram #(.RAM_WIDTH(16), .RAM_DEPTH(240), .RAM_PERFORMANCE("HIGH_PERFORMANCE")) 
      line_buffer (
      .addra(hcount_in), .addrb(hcount_in),  
      .dina(pixel_data_in), .dinb(pixel_data_in), 
      .clka(clk_in),
      .wea(write_enable[i]), .web(1'b0),             
      .ena(1'b1), .enb(1'b1),  
      .rsta(rst_in), .rstb(rst_in),       
      .regcea(1'b0), .regceb(1'b1),                        
      .douta(data_out_write[i]), .doutb(data_out_read[i]));
    end
  endgenerate

  always_ff @(posedge clk_in) begin 

    hcount_out_1 <= hcount_in;
    hcount_out_2 <= hcount_out_1;
    hcount_out <= hcount_out_2;

    vcount_out_1 <= vcount_in;
    vcount_out_2 <= vcount_out_1;
    vcount_out <= vcount_out_2;

    data_valid_out_pipe_1 <= data_valid_in; 
    data_valid_out_pipe_2 <= data_valid_out_pipe_1;
    data_valid_out <= data_valid_out_pipe_2;
   
    if (data_valid_in == 1'b1) begin 
      vcount_in_old <= vcount_in; 

      if (rst_in == 1'b1) begin 
        data_valid_out <= 1'b0;
        write_enable <= 4'b0001;
      end 

      if (vcount_in_old != vcount_in) begin 
        case(write_enable)
          4'b0001: write_enable <= 4'b0010; 
          4'b0010: write_enable <= 4'b0100; 
          4'b0100: write_enable <= 4'b1000; 
          4'b1000: write_enable <= 4'b0001; 
        endcase
      end 

      if (write_enable == 4'b0001) begin //writing to the 1st BRAM
        line_buffer_out[0] <= data_out_read[3];
        line_buffer_out[1] <= data_out_read[2];
        line_buffer_out[2] <= data_out_read[1];
      end 
      if (write_enable == 4'b0010) begin //writing to the 2nd BRAM
        line_buffer_out[0] <= data_out_read[0];
        line_buffer_out[1] <= data_out_read[3];
        line_buffer_out[2] <= data_out_read[2];
      end 
      if (write_enable == 4'b0100) begin //writing to the 3rd BRAM
        line_buffer_out[0] <= data_out_read[1];
        line_buffer_out[1] <= data_out_read[0];
        line_buffer_out[2] <= data_out_read[3];
      end 
      if (write_enable == 4'b1000) begin //writing to the 4th BRAM
        line_buffer_out[0] <= data_out_read[2]; 
        line_buffer_out[1] <= data_out_read[1];
        line_buffer_out[2] <= data_out_read[0];
      end 
    end 

  end 
  

endmodule


`default_nettype wire
