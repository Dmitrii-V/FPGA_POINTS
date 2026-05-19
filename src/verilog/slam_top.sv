`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.05.2026 20:12:37
// Design Name: 
// Module Name: slam_top
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
slam_top 
#(
    .P_MAX_TILE (  ),
    .P_MAX_W    (  ),
    .P_MAX_H    (  ),
    .PW_IMG     (  )
) slam_top (
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
module slam_top
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
 
clahe_hist 
#(
    .P_MAX_TILE ( P_MAX_TILE ),
    .P_MAX_W    ( P_MAX_W    ),
    .P_MAX_H    ( P_MAX_H    ),
    .PW_IMG     ( PW_IMG     )
) clahe_hist (
    .CLK             ( CLK             ), //  in,              
    .RST             ( RST             ), //  in,               
    .IMG_DIN_TDATA   ( IMG_DIN_TDATA   ), //  in, [PW_IMG-1:0] 
    .IMG_DIN_TVALID  ( IMG_DIN_TVALID  ), //  in,              
    .IMG_DIN_TREADY  ( IMG_DIN_TREADY  ), // out,              
    .IMG_DOUT_TDATA  ( IMG_DOUT_TDATA  ), // out, [PW_IMG-1:0] 
    .IMG_DOUT_TVALID ( IMG_DOUT_TVALID ), // out,              
    .IMG_DOUT_TREADY ( IMG_DOUT_TREADY )  //  in,              
    ); 


    
endmodule
`default_nettype wire