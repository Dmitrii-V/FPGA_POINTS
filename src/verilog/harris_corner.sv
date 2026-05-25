`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.05.2026 00:29:39
// Design Name: 
// Module Name: harris_corner
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
harris_corner 
#( 
    .P_MAX_W      (  ),
    .P_MAX_H      (  ),
    .PW_IMG       (  )
)harris_corner(
    .CLK            (  ), // input                  
    .RST            (  ), // input                  
                                 
    .IMG_DIN_TDATA  (  ), // input  [PW_IMG-1:0]    
    .IMG_DIN_TVALID (  ), // input                  
    .IMG_DIN_TREADY (  ), // output                 
    .IMG_DIN_TLAST  (  )     input                  
    
    );
*/
module harris_corner
#(
    parameter P_SOBEL_SIZE =    3,
    parameter P_MAX_W      = 1920,
    parameter P_MAX_H      = 1080,
    parameter PW_IMG       = 8
)(
    input  wire                 CLK,
    input  wire                 RST,
    output wire                 ERROR_WR_ON_APPEND,
    
    input  wire [PW_IMG-1:0]    IMG_DIN_TDATA,
    input  wire                 IMG_DIN_TVALID,
    output wire                 IMG_DIN_TREADY,
    input  wire                 IMG_DIN_TLAST
    
    );
    
    
localparam LPW_SOBEL = (PW_IMG + 2 + 3)*2;    
wire [LPW_SOBEL-1:0] w_ixx_dout       ;    
wire [LPW_SOBEL-1:0] w_iyy_dout       ;    
wire [LPW_SOBEL-1:0] w_ixy_dout       ;    
wire                 w_ixxyyxy_dout_dv;    
wire                 w_ixxyyxy_dout_last;    
    
sobel_xy 
#(
    .P_SOBEL_SIZE ( P_SOBEL_SIZE  ),
    .P_MAX_W      ( P_MAX_W       ),
    .P_MAX_H      ( P_MAX_H       ),
    .PW_IMG       ( PW_IMG        ),
    .PW_DOUT      ( LPW_SOBEL     ) // +2 - to mul by "-2", +3 - to sum 6 values 
)sobel_xy(
    .CLK                ( CLK                 ), // input                  
    .RST                ( RST                 ), // input                  
    .ERROR_WR_ON_APPEND ( ERROR_WR_ON_APPEND  ), // input                  
    .IMG_DIN_TDATA      ( IMG_DIN_TDATA       ), // input  [PW_IMG-1:0]    
    .IMG_DIN_TVALID     ( IMG_DIN_TVALID      ), // input                  
    .IMG_DIN_TREADY     ( IMG_DIN_TREADY      ), // output                 
    .IMG_DIN_TLAST      ( IMG_DIN_TLAST       ), // input                  
    .IXX_DOUT           ( w_ixx_dout          ), // output [PW_DOUT-1:0]   
    .IYY_DOUT           ( w_iyy_dout          ), // output [PW_DOUT-1:0]   
    .IXY_DOUT           ( w_ixy_dout          ), // output [PW_DOUT-1:0]   
    .IXXYYXY_DOUT_DV    ( w_ixxyyxy_dout_dv   ), // output                 
    .IXXYYXY_DOUT_LAST  ( w_ixxyyxy_dout_last )  // output                 
    );    


integer f_sobel = -1;
always @(posedge(CLK))
    begin
        if ( f_sobel == -1 )
            f_sobel = $fopen("D:/tmp/vivado_sigs/sobel_matrices.txt");
        else
            begin
                if ( w_ixxyyxy_dout_dv )
                    $fwrite(f_sobel, "%d %d %d\n", w_ixx_dout, w_iyy_dout, w_ixy_dout);
            end
            
    end
    
    
endmodule
`default_nettype wire
