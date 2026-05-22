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
    .IMG_DIN_TLAST   (  ), // out,              
    .IMG_DOUT_TDATA  (  ), // out, [PW_IMG-1:0] 
    .IMG_DOUT_TVALID (  ), // out,              
    .IMG_DOUT_TREADY (  ), //  in,              
    .IMG_DOUT_TLAST  (  )  //  in,              
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
    input  wire              IMG_DIN_TLAST,
    
    output wire [PW_IMG-1:0] IMG_DOUT_TDATA,
    output wire              IMG_DOUT_TVALID,
    input  wire              IMG_DOUT_TREADY,  
    output wire              IMG_DOUT_TLAST  
    );
 
localparam LP_LUT_ADDR = PW_IMG + 2*$clog2(P_MAX_TILE); 

wire [PW_IMG-1:0]       w_lut_data     ;
wire [LP_LUT_ADDR-1:0]  w_lut_data_addr;
wire                    w_lut_data_dv  ;

wire [PW_IMG-1:0]       w_img_clahe_to_ddr_tdata   ;
wire                    w_img_clahe_to_ddr_tvalid  ;
wire                    w_img_clahe_to_ddr_tready  ;
wire                    w_img_clahe_to_ddr_tlast   ;
wire [PW_IMG-1:0]       w_img_clahe_from_ddr_tdata   ;
wire                    w_img_clahe_from_ddr_tvalid  ;
wire                    w_img_clahe_from_ddr_tready  ;
wire                    w_img_clahe_from_ddr_tlast   ;
wire [PW_IMG-1:0]       w_img_clahe_result_tdata   ;
wire                    w_img_clahe_result_tvalid  ;
wire                    w_img_clahe_result_tready  ;
wire                    w_img_clahe_result_tlast   ;


clahe_hist 
#(
    .P_MAX_TILE ( P_MAX_TILE  ),
    .P_MAX_W    ( P_MAX_W     ),
    .P_MAX_H    ( P_MAX_H     ),
    .PW_IMG     ( PW_IMG      ),
    .PW_LUT_ADDR( LP_LUT_ADDR )
) clahe_hist (
    .CLK             ( CLK                       ), //  in,              
    .RST             ( RST                       ), //  in,               
    
    // Grayscale image from sensor:
    .IMG_DIN_TDATA   ( IMG_DIN_TDATA             ), //  in, [PW_IMG-1:0] , AXIS TDATA,
    .IMG_DIN_TVALID  ( IMG_DIN_TVALID            ), //  in,              
    .IMG_DIN_TREADY  ( IMG_DIN_TREADY            ), // out,             
    .IMG_DIN_TLAST   ( IMG_DIN_TLAST             ), //  in,             
    
    // CLAHE Lut result:
    .LUT_DOUT        ( w_lut_data                ), // out, [PW_IMG-1:0] 
    .LUT_DOUT_ADDR   ( w_lut_data_addr           ), // out, [PW_LUT_ADDR-1:0]
    .LUT_DOUT_DV     ( w_lut_data_dv             ), // out, 
    
    // Grayscale Image to DDR-FIFO: 
    .IMG_DOUT_TDATA  ( w_img_clahe_to_ddr_tdata  ), // out, [PW_IMG-1:0] 
    .IMG_DOUT_TVALID ( w_img_clahe_to_ddr_tvalid ), // out,              
    .IMG_DOUT_TREADY ( w_img_clahe_to_ddr_tready ), //  in,            
    .IMG_DOUT_TLAST  ( w_img_clahe_to_ddr_tlast  )  // out,  
    ); 


clahe_lut 
#(
    .P_MAX_TILE ( P_MAX_TILE  ),
    .P_MAX_W    ( P_MAX_W     ),
    .P_MAX_H    ( P_MAX_H     ),
    .PW_IMG     ( PW_IMG      ),
    .PW_LUT_ADDR( LP_LUT_ADDR )
) clahe_lut (
    .CLK             ( CLK                         ), //  in,              
    .RST             ( RST                         ), //  in,               
    
    // Grayscale image DDR-fifo:
    .IMG_DIN_TDATA   ( w_img_clahe_from_ddr_tdata  ), //  in, [PW_IMG-1:0] , AXIS TDATA,
    .IMG_DIN_TVALID  ( w_img_clahe_from_ddr_tvalid ), //  in,              
    .IMG_DIN_TREADY  ( w_img_clahe_from_ddr_tready ), // out,             
    .IMG_DIN_TLAST   ( w_img_clahe_from_ddr_tlast  ), //  in,             
    
    // CLAHE Lut result:
    .LUT_DIN         ( w_lut_data                  ), //  in, [PW_IMG-1:0] 
    .LUT_DIN_ADDR    ( w_lut_data_addr             ), //  in, [PW_LUT_ADDR-1:0]
    .LUT_DIN_DV      ( w_lut_data_dv               ), //  in, 
    
    // Grayscale Image after CLAHE to Harris: 
    .IMG_DOUT_TDATA  ( w_img_clahe_result_tdata    ), // out, [PW_IMG-1:0] 
    .IMG_DOUT_TVALID ( w_img_clahe_result_tvalid   ), // out,              
    .IMG_DOUT_TREADY ( w_img_clahe_result_tready   ), //  in,            
    .IMG_DOUT_TLAST  ( w_img_clahe_result_tlast    )  // out,  
    ); 

fifo_ddr_imitator_clahe fifo_ddr_imitator_clahe (
  .s_axis_aresetn   ( !RST                        ), // input wire s_axis_aresetn         
  .s_axis_aclk      ( CLK                         ), // input wire s_axis_aclk       
  .s_axis_tdata     ( w_img_clahe_to_ddr_tdata    ), // input wire [7 : 0] s_axis_tdata                 
  .s_axis_tvalid    ( w_img_clahe_to_ddr_tvalid   ), // input wire s_axis_tvalid           
  .s_axis_tready    ( w_img_clahe_to_ddr_tready   ), // output wire s_axis_tready         
  .s_axis_tlast     ( w_img_clahe_to_ddr_tlast    ), // input wire s_axis_tlast          
  .m_axis_tdata     ( w_img_clahe_from_ddr_tdata  ), // output wire [7 : 0] m_axis_tdata           
  .m_axis_tvalid    ( w_img_clahe_from_ddr_tvalid ), // output wire m_axis_tvalid          
  .m_axis_tready    ( w_img_clahe_from_ddr_tready ), // input wire m_axis_tready         
  .m_axis_tlast     ( w_img_clahe_from_ddr_tlast  )  // output wire m_axis_tlast             
);

integer f_lut = -1;
always @(posedge(CLK))
    begin
        if ( f_lut == -1 )
            f_lut = $fopen("D:/tmp/vivado_sigs/slam_lut.txt");
        else
            if ( w_lut_data_dv )
                $fwrite(f_lut, "%d %d\n", w_lut_data_addr, w_lut_data);
    end
    
integer f_lut_dout = -1;
always @(posedge(CLK))
    begin
        if ( f_lut_dout == -1 )
            f_lut_dout = $fopen("D:/tmp/vivado_sigs/slam_lut_dout.txt");
        else
            if ( w_img_clahe_result_tvalid )
                $fwrite(f_lut_dout, "%d\n", w_img_clahe_result_tdata);
    end
    
endmodule
`default_nettype wire