`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.05.2026 00:29:39
// Design Name: 
// Module Name: conv_2d_harris
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


module conv_2d_harris
#(
    parameter PW_IMG = 8
)(
    input  wire                 CLK,
    input  wire                 RST,
    
    input  wire [PW_IMG-1:0]    IMG_DIN_TDATA,
    input  wire                 IMG_DIN_TVALID,
    output wire                 IMG_DIN_TREADY,
    input  wire                 IMG_DIN_TLAST,
    
    output wire [PW_IMG-1:0]    IMG_DOUT_TDATA,
    output wire                 IMG_DOUT_TVALID,
    input  wire                 IMG_DOUT_TREADY,
    output wire                 IMG_DOUT_TLAST
    );
endmodule
`default_nettype wire 
