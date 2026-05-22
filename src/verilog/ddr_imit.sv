`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.05.2026 18:35:22
// Design Name: 
// Module Name: ddr_imit
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
ddr_imit ddr_imit(
    .CLK                (  ), // input ,             
    .RST                (  ), // input ,              
    .IMG_DIN_GS_TDATA   (  ), // input ,[PW_DIN-1:0] 
    .IMG_DIN_GS_TVALID  (  ), // input ,             
    .IMG_DIN_GS_TREADY  (  ), // output,             
    .IMG_DIN_GS_TLAST   (  ), // input ,              
    .IMG_DOUT_GS_TVALID (  ), // output,             
    .IMG_DOUT_GS_TDATA  (  ), // output,[PW_DIN-1:0] 
    .IMG_DOUT_GS_TREADY (  ), // input ,             
    .IMG_DOUT_GS_TLAST  (  )  // output,             
    );
*/
module ddr_imit
#(
    parameter P_N_BYTES = 16,
    parameter PW_DIN    =  8
)(
    input  wire              CLK,
    input  wire              RST,
    
    input  wire [PW_DIN-1:0] IMG_DIN_GS_TDATA,
    input  wire              IMG_DIN_GS_TVALID,
    output wire              IMG_DIN_GS_TREADY,
    input  wire              IMG_DIN_GS_TLAST,
    
    output wire              IMG_DOUT_GS_TVALID,
    output wire [PW_DIN-1:0] IMG_DOUT_GS_TDATA ,
    input  wire              IMG_DOUT_GS_TREADY,
    output wire              IMG_DOUT_GS_TLAST  
    );
    
axis_dwidth_converter_1_to_16_b axis_dwidth_converter_1_to_16_b (
  .aclk             ( CLK               ), // input wire aclk                                      
  .aresetn          ( !RST              ), // input wire aresetn                             
  .s_axis_tvalid    ( IMG_DIN_GS_TVALID ), // input wire s_axis_tvalid           
  .s_axis_tready    ( IMG_DIN_GS_TREADY ), // output wire s_axis_tready          
  .s_axis_tdata     ( IMG_DIN_GS_TDATA  ), // input wire [7 : 0] s_axis_tdata      
  .s_axis_tkeep     ( IMG_DIN_GS_TVALID ), // input wire [0 : 0] s_axis_tkeep      
  .s_axis_tlast     ( IMG_DIN_GS_TLAST  ), // input wire s_axis_tlast              
  .m_axis_tvalid    ( w_fifo_din_tvalid ), // output wire m_axis_tvalid          
  .m_axis_tready    ( w_fifo_din_tready ), // input wire m_axis_tready           
  .m_axis_tdata     ( w_fifo_din_tdata  ), // output wire [127 : 0] m_axis_tdata   
  .m_axis_tkeep     ( w_fifo_din_tkeep  ), // output wire [15 : 0] m_axis_tkeep    
  .m_axis_tlast     ( w_fifo_din_tlast  )  // output wire m_axis_tlast             
);
                                       
wire                        w_fifo_din_tvalid;
wire                        w_fifo_din_tready;
wire [PW_DIN*P_N_BYTES-1:0] w_fifo_din_tdata ;
wire [P_N_BYTES-1:0]        w_fifo_din_tkeep ;
wire                        w_fifo_din_tlast ;                                       
wire                        w_fifo_dout_tvalid;
wire                        w_fifo_dout_tready;
wire [PW_DIN*P_N_BYTES-1:0] w_fifo_dout_tdata ;
wire [P_N_BYTES-1:0]        w_fifo_dout_tkeep ;
wire                        w_fifo_dout_tlast ;

fifo_ddr_imitator_clahe fifo_ddr_imitator_clahe (
  .s_axis_aresetn( !RST               ), // input wire s_axis_aresetn
  .s_axis_aclk   ( CLK                ), // input wire s_axis_aclk
  .s_axis_tvalid ( w_fifo_din_tvalid  ), // input wire s_axis_tvalid
  .s_axis_tready ( w_fifo_din_tready  ), // output wire s_axis_tready
  .s_axis_tdata  ( w_fifo_din_tdata   ), // input wire [127 : 0] s_axis_tdata
  .s_axis_tkeep  ( w_fifo_din_tkeep   ), // input wire [15 : 0] s_axis_tkeep
  .s_axis_tlast  ( w_fifo_din_tlast   ), // input wire s_axis_tlast
  .m_axis_tvalid ( w_fifo_dout_tvalid ), // output wire m_axis_tvalid
  .m_axis_tready ( w_fifo_dout_tready ), // input wire m_axis_tready
  .m_axis_tdata  ( w_fifo_dout_tdata  ), // output wire [127 : 0] m_axis_tdata
  .m_axis_tkeep  ( w_fifo_dout_tkeep  ), // output wire [15 : 0] m_axis_tkeep
  .m_axis_tlast  ( w_fifo_dout_tlast  )  // output wire m_axis_tlast
);     


axis_dwidth_converter_16_to_1_b axis_dwidth_converter_16_to_1_b (
  .aclk             ( CLK                ), // input wire aclk                                     
  .aresetn          ( !RST               ), // input wire aresetn                            
  .s_axis_tvalid    ( w_fifo_dout_tvalid ), // input wire s_axis_tvalid          
  .s_axis_tready    ( w_fifo_dout_tready ), // output wire s_axis_tready         
  .s_axis_tdata     ( w_fifo_dout_tdata  ), // input wire [127 : 0] s_axis_tdata   
  .s_axis_tkeep     ( w_fifo_dout_tkeep  ), // input wire [15 : 0] s_axis_tkeep    
  .s_axis_tlast     ( w_fifo_dout_tlast  ), // input wire s_axis_tlast             
  .m_axis_tvalid    ( IMG_DOUT_GS_TVALID ), // output wire m_axis_tvalid         
  .m_axis_tready    ( IMG_DOUT_GS_TREADY ), // input wire m_axis_tready          
  .m_axis_tdata     ( IMG_DOUT_GS_TDATA  ), // output wire [7 : 0] m_axis_tdata    
  .m_axis_tkeep     (                    ), // output wire [0 : 0] m_axis_tkeep    
  .m_axis_tlast     ( IMG_DOUT_GS_TLAST  )  // output wire m_axis_tlast            
);
endmodule
`default_nettype wire
