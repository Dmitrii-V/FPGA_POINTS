`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.05.2026 19:45:18
// Design Name: 
// Module Name: clahe_hist
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

/*
clahe_hist 
#(
    .P_MAX_TILE (  ),
    .P_MAX_W    (  ),
    .P_MAX_H    (  ),
    .PW_IMG     (  )
) clahe_hist (
    .CLK             (  ), //  in,              
    .RST             (  ), //  in,               
    .IMG_DIN_TDATA   (  ), //  in, [PW_IMG-1:0] 
    .IMG_DIN_TVALID  (  ), //  in,              
    .IMG_DIN_TREADY  (  ), // out,              
    .IMG_DOUT_TDATA  (  ), // out, [PW_IMG-1:0] 
    .IMG_DOUT_TVALID (  ), // out,              
    .IMG_DOUT_TREADY (  )  //  in,              
    );
*/
module clahe_hist
#(
    parameter P_MAX_TILE =    8,
    parameter P_MAX_W    = 1920,
    parameter P_MAX_H    = 1080,
    parameter PW_IMG     =    8
)(
    input  wire              CLK,
    input  wire              RST,
    
    input  wire [PW_IMG-1:0] IMG_DIN_TDATA,
    input  wire              IMG_DIN_TVALID,
    output wire              IMG_DIN_TREADY,
    
    output wire [PW_IMG-1:0] IMG_DOUT_TDATA,
    output wire              IMG_DOUT_TVALID,
    input  wire              IMG_DOUT_TREADY  
    );


assign IMG_DIN_TREADY = 1'b1;
// define reg, but want it to be BRAM..
reg [$clog2(P_MAX_W*P_MAX_H)-1:0] r_hist_bram [0:P_MAX_TILE*P_MAX_TILE*(2**PW_IMG)-1];    
initial begin
    for ( integer ii = 0; ii < P_MAX_TILE*P_MAX_TILE*(2**PW_IMG); ii = ii + 1 )
        r_hist_bram[ii] = 0;
end
    
reg [$clog2(P_MAX_W/P_MAX_TILE)-1:0] r_tile_cnt_x;
reg [$clog2(P_MAX_W/P_MAX_TILE)-1:0] r_tile_cnt_y;
reg [$clog2(P_MAX_W/P_MAX_TILE)-1:0] r_tile_max_minus_one_x = (P_MAX_W/P_MAX_TILE);
reg [$clog2(P_MAX_W/P_MAX_TILE)-1:0] r_tile_max_minus_one_y = (P_MAX_H/P_MAX_TILE);
reg [$clog2(P_MAX_TILE)        -1:0] r_clahe_tiles_minus_one = (P_MAX_TILE-1);
reg [$clog2(P_MAX_TILE-1)      -1:0] r_hist_x;
reg [$clog2(P_MAX_TILE-1)      -1:0] r_hist_y;

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

// count hist:
always @(posedge(CLK))
    begin
        if( IMG_DIN_TVALID && IMG_DIN_TREADY )
            r_hist_bram[{r_hist_y, r_hist_x, IMG_DIN_TDATA}] <= r_hist_bram[{r_hist_y, r_hist_x, IMG_DIN_TDATA}] + 1'b1; 
    end    
endmodule
`default_nettype wire
