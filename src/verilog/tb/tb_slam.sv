`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.05.2026 19:41:49
// Design Name: 
// Module Name: tb_slam
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


module tb_slam
#(
    parameter PH_CLIP_VAL           =    9,
    parameter P_USE_IMG_GENERATOR   =    0,
    parameter P_MAX_TILE            =    8,
    parameter P_MAX_W               =  320,//1920,
    parameter P_MAX_H               =  240,//1080,
    parameter PW_IMG                =    8
);



reg CLK = 0;
reg RST = 0;
wire [PW_IMG-1:0]   w_img_din_tdata ;
wire                w_img_din_tvalid;
wire                w_img_din_tready;


reg              r_img_din_tvalid  = 'b0;
wire             w_s_img_din_tready;
reg  [PW_IMG-1:0]r_img_din_tdata   = 'b0;
reg              r_img_din_tlast   = 'b0;
wire             w_img_din_tvalid ;
wire             w_img_din_tready ;
wire [PW_IMG-1:0]w_img_din_tdata ;
wire             w_img_din_tlast ;
parameter PERIOD = 20;
initial begin
    CLK = 0;
    forever
        begin
            #(PERIOD/2) CLK = ~CLK;
        end
end

slam_top 
#(
    .PH_CLIP_VAL( PH_CLIP_VAL ),
    .P_MAX_TILE ( P_MAX_TILE  ),
    .P_MAX_W    ( P_MAX_W     ),
    .P_MAX_H    ( P_MAX_H     ),
    .PW_IMG     ( PW_IMG      )
) slam_top (
    .CLK             ( CLK              ), //  in,              
    .RST             ( RST              ), //  in,               
    .IMG_DIN_TDATA   ( w_img_din_tdata  ), //  in, [PW_IMG-1:0] 
    .IMG_DIN_TVALID  ( w_img_din_tvalid ), //  in,              
    .IMG_DIN_TREADY  ( w_img_din_tready ), // out,              
    .IMG_DIN_TLAST   ( w_img_din_tlast  ), // out,              
    .IMG_DOUT_TDATA  (  ), // out, [PW_IMG-1:0] 
    .IMG_DOUT_TVALID (  ), // out,              
    .IMG_DOUT_TREADY (  )  //  in,              
    );

wire w_prog_full;
axis_data_fifo_0 axis_data_fifo_0 (
  .s_axis_aresetn   ( ~RST             ), // input wire s_axis_aresetn         
  .s_axis_aclk      ( CLK              ), // input wire s_axis_aclk                 
  .s_axis_tvalid    ( r_img_din_tvalid ), // input wire s_axis_tvalid           
  .s_axis_tready    ( w_s_img_din_tready ), // output wire s_axis_tready          
  .s_axis_tdata     ( r_img_din_tdata  ), // input wire [7 : 0] s_axis_tdata      
  .s_axis_tlast     ( r_img_din_tlast  ), // input wire s_axis_tlast              
  .m_axis_tvalid    ( w_img_din_tvalid ), // output wire m_axis_tvalid          
  .m_axis_tready    ( w_img_din_tready ), // input wire m_axis_tready           
  .m_axis_tdata     ( w_img_din_tdata  ), // output wire [7 : 0] m_axis_tdata     
  .m_axis_tlast     ( w_img_din_tlast  ), // output wire m_axis_tlast             
  .prog_full        ( w_prog_full      )  // output wire prog_full                      
);

reg r_init_done = 1'b0;
reg [15:0] r_cnt_x = 0;
reg [15:0] r_cnt_y = 0;

generate
    if ( P_USE_IMG_GENERATOR )
        begin
            always @( posedge(CLK) )
                begin
                    if ( r_init_done && ~w_prog_full )
                        begin
                            if ( r_img_din_tdata == 'd31)
                                r_img_din_tdata  <= 'b0;
                            else
                                r_img_din_tdata  <= r_img_din_tdata + 1;
                            r_img_din_tvalid <= 1'b1;
                            r_img_din_tlast  <= ( r_cnt_y == (P_MAX_H-1)) & ( r_cnt_x == (P_MAX_W-1) );
                            if ( r_cnt_x == (P_MAX_W-1) )
                                begin
                                    r_cnt_x <= 0;
                                    if ( r_cnt_y == (P_MAX_H-1))
                                        r_cnt_y <= 'b0;
                                    else
                                        r_cnt_y <= r_cnt_y + 1;
                                end
                            else
                                r_cnt_x <= r_cnt_x + 1;
                        end
                    else
                        begin
                            r_img_din_tdata  <= r_img_din_tdata;
                            r_img_din_tvalid <= 1'b0;
                            r_img_din_tlast  <= 1'b0;
                        end
                end
        end
    else // read from file
        begin
            integer f_img = - 1;
            reg [31:0] r_pix_cnt = 0;
            always @(posedge(CLK))
                begin
                    if ( f_img == -1 )
                        begin
                        f_img = $fopen("D:/tmp/vivado_sigs/img_test.txt", "r");
                        r_pix_cnt = 0;
                        end
                    else
                        begin
                            if ( r_init_done && ~w_prog_full && r_pix_cnt < P_MAX_H*P_MAX_W )
                                begin
                                    $fscanf(f_img, "%d\n", r_img_din_tdata);
                                    r_img_din_tvalid <= 1'b1;
                                    r_img_din_tlast  <= (r_pix_cnt == P_MAX_H*P_MAX_W-1) ? 1'b1: 1'b0;
                                    r_pix_cnt        <= r_pix_cnt  +1;
                                end
                            else
                                begin
                                    r_img_din_tdata  <= r_img_din_tdata;
                                    r_img_din_tvalid <= 1'b0;
                                    r_img_din_tlast  <= 1'b0;
                                end
                        end
                        
                end    
        end
    
endgenerate        
initial begin
    r_init_done = 0;
    RST = 1;
    #100;
    @(posedge(CLK));
    #1;
    RST = 0;
    #(PERIOD*40);
    r_init_done = 1;
end



endmodule
`default_nettype wire

