`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.05.2026 14:04:23
// Design Name: 
// Module Name: clahe_lut
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clahe_lut
#(
    parameter P_MAX_TILE  =    8,
    parameter P_MAX_W     = 1920,
    parameter P_MAX_H     = 1080,
    parameter PW_IMG      =    8,
    parameter PW_LUT_ADDR =    PW_IMG + $clog2(P_MAX_TILE-1) + $clog2(P_MAX_TILE-1) 
)(
    input  wire                     CLK,
    input  wire                     RST,
    
    input  wire [PW_IMG-1:0]        IMG_DIN_TDATA,
    input  wire                     IMG_DIN_TVALID,
    output wire                     IMG_DIN_TREADY,
    input  wire                     IMG_DIN_TLAST,
    
    input  wire [PW_IMG-1:0]        LUT_DIN,
    input  wire [PW_LUT_ADDR-1:0]   LUT_DIN_ADDR,
    input  wire                     LUT_DIN_DV, 
    
    output wire [PW_IMG-1:0]        IMG_DOUT_TDATA ,
    output wire                     IMG_DOUT_TVALID,
    input  wire                     IMG_DOUT_TREADY,  
    output wire                     IMG_DOUT_TLAST  
    );
    

reg    r_img_din_tready = 1'b0;
assign IMG_DIN_TREADY = r_img_din_tready;    

reg [$clog2(P_MAX_W/P_MAX_TILE)-1:0] r_tile_cnt_x;
reg [$clog2(P_MAX_W/P_MAX_TILE)-1:0] r_tile_cnt_y;
reg [$clog2(P_MAX_W/P_MAX_TILE)-1:0] r_tile_max_minus_one_x = (P_MAX_W/P_MAX_TILE)-1;
reg [$clog2(P_MAX_W/P_MAX_TILE)-1:0] r_tile_max_minus_one_y = (P_MAX_H/P_MAX_TILE)-1;
reg [$clog2(P_MAX_TILE)        -1:0] r_clahe_tiles_minus_one = (P_MAX_TILE-1);
reg [$clog2(P_MAX_TILE-1)      -1:0] r_hist_x;
reg [$clog2(P_MAX_TILE-1)      -1:0] r_hist_y;
reg                                  r_tile_line_done = 1'b0;
 
// Count pixels to define the number of the current tile:
always @(posedge(CLK))
    begin 
        if ( RST )
            r_hist_x <= 'b0;
        else if ( IMG_DIN_TVALID && IMG_DIN_TREADY 
              && r_tile_cnt_x >= r_tile_max_minus_one_x )
              begin
                  if (r_hist_x     == r_clahe_tiles_minus_one )
                        r_hist_x     <= 'b0;
                  else
                        r_hist_x     <= r_hist_x + 1'b1;
              end
            
        if ( RST )
            r_hist_y <= 'b0;
        else if ( IMG_DIN_TVALID && IMG_DIN_TREADY 
              && r_tile_cnt_x >= r_tile_max_minus_one_x 
              && r_tile_cnt_y >= r_tile_max_minus_one_y 
              && r_hist_x     == r_clahe_tiles_minus_one)
            r_hist_y     <= r_hist_y + 1'b1;
        
        if ( IMG_DIN_TVALID && IMG_DIN_TREADY 
              && r_tile_cnt_x >= r_tile_max_minus_one_x 
              && r_tile_cnt_y >= r_tile_max_minus_one_y 
              && r_hist_x     == r_clahe_tiles_minus_one)
            r_tile_line_done <= 1'b1;
        else
            r_tile_line_done <= 1'b0;
            
        if ( RST )
            begin
                r_tile_cnt_x <= 'b0;
                r_tile_cnt_y <= 'b0; 
            end
        else if ( IMG_DIN_TVALID && IMG_DIN_TREADY )
            begin
                if ( r_tile_cnt_x >= r_tile_max_minus_one_x )
                    begin
                        r_tile_cnt_x <= 'b0;
                        if ( r_hist_x == r_clahe_tiles_minus_one )
                            begin
                                if ( r_tile_cnt_y >= r_tile_max_minus_one_y ) 
                                    r_tile_cnt_y <= 'b0; 
                                else
                                    r_tile_cnt_y <= r_tile_cnt_y + 1'b1;
                            end
                    end
                else
                    r_tile_cnt_x <= r_tile_cnt_x + 1'b1;
            end
    end

always @( posedge(CLK) )
    begin
        if ( RST )
            r_img_din_tready <= 1'b0;
        else if ( LUT_DIN_DV 
           && (LUT_DIN_ADDR[$clog2(P_MAX_TILE-1) + PW_IMG-1:0] == {r_clahe_tiles_minus_one, {PW_IMG{1'b1}}})
           )
            r_img_din_tready <= 1'b1;
        else if ( IMG_DIN_TVALID && IMG_DIN_TREADY 
              && r_tile_cnt_x >= r_tile_max_minus_one_x 
              && r_tile_cnt_y >= r_tile_max_minus_one_y 
              && r_hist_x     == r_clahe_tiles_minus_one)
            r_img_din_tready <= 1'b0;
        
    end


    
reg  [PW_LUT_ADDR-1:0] r_lut_addrb;
reg                    r_lut_addrb_dv;
reg                    r_lut_addrb_dv_d;
reg                    r_lut_addrb_last;
reg                    r_lut_addrb_last_d;
wire [PW_IMG-1:0]      w_lut_dout; 
wire                   w_lut_dout_dv   = r_lut_addrb_dv_d; 
wire                   w_lut_dout_last = r_lut_addrb_last_d;
 
bram_clahe_lut bram_clahe_lut (
  .clka     ( CLK           ), // input wire clka             
  .wea      ( LUT_DIN_DV    ), // input wire [0 : 0] wea        
  .addra    ( LUT_DIN_ADDR  ), // input wire [13 : 0] addra 
  .dina     ( LUT_DIN       ), // input wire [7 : 0] dina     
  .clkb     ( CLK           ), // input wire clkb             
  .addrb    ( r_lut_addrb   ), // input wire [13 : 0] addrb 
  .doutb    ( w_lut_dout    )  // output wire [7 : 0] doutb 
); 

// count hist:  
reg               r_img_din_data_dv = 1'b0;
reg               r_img_din_data_dv_d = 1'b0;
//reg               r_img_din_data_dv_dd = 1'b0;
always @(posedge(CLK))
    begin
        r_lut_addrb        <= (IMG_DIN_TVALID & IMG_DIN_TREADY)? {r_hist_y, r_hist_x, IMG_DIN_TDATA} : r_lut_addrb;
        r_lut_addrb_dv     <= IMG_DIN_TVALID & IMG_DIN_TREADY;
        r_lut_addrb_dv_d   <= r_lut_addrb_dv;   
        r_lut_addrb_last   <= IMG_DIN_TLAST;
        r_lut_addrb_last_d <= r_lut_addrb_last;
    end     
     
assign IMG_DOUT_TDATA  = w_lut_dout; 
assign IMG_DOUT_TVALID = w_lut_dout_dv;
//assign IMG_DOUT_TREADY,  
assign IMG_DOUT_TLAST  = w_lut_dout_last;
    
endmodule
`default_nettype wire
