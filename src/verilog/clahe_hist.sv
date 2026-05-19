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
    input  wire              IMG_DIN_TLAST,
    
    output wire [PW_IMG-1:0] IMG_DOUT_TDATA,
    output wire              IMG_DOUT_TVALID,
    input  wire              IMG_DOUT_TREADY,  
    output wire              IMG_DOUT_TLAST  
    );


reg  r_img_din_tready = 1'b0;
assign IMG_DIN_TREADY = r_img_din_tready;
reg [ 1:0] r_cnt = 'b0;
always @(posedge(CLK))
    begin
        r_cnt <= r_cnt + 1'b1;
        r_img_din_tready <= &r_cnt;
    end
// define reg, but want it to be BRAM..
reg [$clog2(P_MAX_W*P_MAX_H)-1:0] r_hist_bram [0:P_MAX_TILE-1][0:P_MAX_TILE-1][0:(2**PW_IMG)-1];    
initial begin
    for ( integer i = 0; i < P_MAX_TILE; i = i + 1 )
        begin
            for ( integer ii = 0; ii < P_MAX_TILE; ii = ii + 1 )
                begin
                    for ( integer iii = 0; iii <  (2**PW_IMG); iii = iii + 1 )
                        r_hist_bram[i][ii][iii] = 0;
                end
        end
end
    
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
                             
reg         r_hist_val_wr_a; 
reg  [13:0] r_hist_val_addra;
reg  [17:0] r_hist_val_dina; 
wire [17:0] w_hist_val_douta;   
reg  [13:0] r_hist_val_addrb; 
reg         r_hist_zero_wr_b;
wire [17:0] w_hist_val_doutb;

wire        w_rst_busy_a;
wire        w_rst_busy_b;
bram_clahe_hist_count bram_clahe_hist_count (
  .clka         ( CLK               ), // input wire clka                       
  .rsta         ( RST               ), // input wire rsta                      
  .wea          ( r_hist_val_wr_a   ), // input wire [0 : 0] wea                 
  .addra        ( r_hist_val_addra  ), // input wire [13 : 0] addra          
  .dina         ( r_hist_val_dina   ), // input wire [17 : 0] dina             
  .douta        ( w_hist_val_douta  ), // output wire [17 : 0] douta         
  .clkb         ( CLK               ), // input wire clkb                      
  .web          ( r_hist_zero_wr_b  ), // input wire [0 : 0] web                 
  .addrb        ( r_hist_val_addrb  ), // input wire [13 : 0] addrb          
  .dinb         ( 18'b0             ), // input wire [17 : 0] dinb             
  .doutb        ( w_hist_val_doutb  ), // output wire [17 : 0] doutb         
  .rsta_busy    ( w_rst_busy_a      ), // output wire rsta_busy      
  .rstb_busy    ( w_rst_busy_b      )  // output wire rstb_busy      
);


// count hist: 
reg  [PW_IMG-1:0] r_img_din_data    = {PW_IMG{1'b0}};
reg               r_img_din_data_dv = 1'b0;
reg               r_img_din_data_dv_d = 1'b0;
//reg               r_img_din_data_dv_dd = 1'b0;
always @(posedge(CLK))
    begin
        r_hist_val_addra  <= (IMG_DIN_TVALID & IMG_DIN_TREADY)? {r_hist_y, r_hist_x, r_img_din_data} : r_hist_val_addra;
        r_img_din_data    <= (IMG_DIN_TVALID & IMG_DIN_TREADY)? IMG_DIN_TDATA : r_img_din_data;
        r_img_din_data_dv <=  IMG_DIN_TVALID & IMG_DIN_TREADY;
        r_img_din_data_dv_d <= r_img_din_data_dv;
        //r_img_din_data_dv_dd <= r_img_din_data_dv_d;
        
        r_hist_val_dina <= w_hist_val_douta + 1'b1;
        r_hist_val_wr_a <= r_img_din_data_dv_d;
        
        if( r_img_din_data_dv )
            r_hist_bram[r_hist_y][r_hist_x][r_img_din_data] <= r_hist_bram[r_hist_y][r_hist_x][r_img_din_data] + 1'b1; 
    end 
    
// read hist:
always @(posedge(CLK))
    begin
        if ( r_tile_line_done )
            begin
                r_hist_val_addrb <= {r_hist_val_addra[$clog2(P_MAX_TILE-1) + PW_IMG +: $clog2(P_MAX_TILE-1)  ], {($clog2(P_MAX_TILE-1)){1'b0}}, 8'b0};
                r_hist_zero_wr_b <= 1'b1;
            end
        else if ( !(&r_hist_val_addrb[($clog2(P_MAX_TILE-1) + PW_IMG)-1:0])  )
            begin
                r_hist_val_addrb <= r_hist_val_addrb + 1'b1;
                r_hist_zero_wr_b <= 1'b1;
            end
        else
            begin
                r_hist_val_addrb <= r_hist_val_addrb;
                r_hist_zero_wr_b <= 1'b0;
            end
    end       
endmodule
`default_nettype wire
