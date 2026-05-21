`timescale 1ns / 1ps
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
endmodule
