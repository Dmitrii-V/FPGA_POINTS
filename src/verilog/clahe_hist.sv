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
    .PW_IMG     (  ),
    .PW_LUT_ADDR(  )
) clahe_hist (
    .CLK             (  ), //  in,              
    .RST             (  ), //  in,               
    
    // Grayscale image from sensor:
    .IMG_DIN_TDATA   (  ), //  in, [PW_IMG-1:0] , AXIS TDATA,
    .IMG_DIN_TVALID  (  ), //  in,              
    .IMG_DIN_TREADY  (  ), // out,             
    .IMG_DIN_TLAST   (  ), //  in,             
    
    // CLAHE Lut result:
    .LUT_DOUT        (  ), // out, [PW_IMG-1:0] 
    .LUT_DOUT_ADDR   (  ), // out, [PW_LUT_ADDR-1:0]
    .LUT_DOUT_DV     (  ), // out, 
    
    // Grayscale Image to DDR-FIFO: 
    .IMG_DOUT_TDATA  (  ), // out, [PW_IMG-1:0] 
    .IMG_DOUT_TVALID (  ), // out,              
    .IMG_DOUT_TREADY (  ), //  in,            
    .IMG_DIN_TLAST   (  )  // out,               
    );
*/
module clahe_hist
#(
    parameter PH_CLIP_VAL  =   37,
    parameter P_MAX_TILE   =    8,
    parameter P_MAX_W      = 1920,
    parameter P_MAX_H      = 1080,
    parameter PH_TOTAL_PIX =   P_MAX_W*P_MAX_H/P_MAX_TILE/P_MAX_TILE,
    parameter PW_IMG       =    8,
    parameter PW_LUT_ADDR  =    PW_IMG + $clog2(P_MAX_TILE-1) + $clog2(P_MAX_TILE-1) 
)(
    input  wire                     CLK,
    input  wire                     RST,
    
    input  wire [PW_IMG-1:0]        IMG_DIN_TDATA,
    input  wire                     IMG_DIN_TVALID,
    output wire                     IMG_DIN_TREADY,
    input  wire                     IMG_DIN_TLAST,
    
    output wire [PW_IMG-1:0]        LUT_DOUT,
    output wire [PW_LUT_ADDR-1:0]   LUT_DOUT_ADDR,
    output wire                     LUT_DOUT_DV, 
    
    output wire [PW_IMG-1:0]        IMG_DOUT_TDATA ,
    output wire                     IMG_DOUT_TVALID,
    input  wire                     IMG_DOUT_TREADY,  
    output wire                     IMG_DOUT_TLAST  
    );


wire w_fifo_dout_prog_full;
reg  r_img_din_tready = 1'b0;
assign IMG_DIN_TREADY = r_img_din_tready;
reg [ 1:0] r_cnt = 'b0;

// control IMG_DIN_TREADY to slow down input data
always @(posedge(CLK))
    begin
        if ( !w_fifo_dout_prog_full )
            begin
                r_cnt <= r_cnt + 1'b1;
                r_img_din_tready <= &r_cnt;
            end
        else
            begin
                r_cnt            <= r_cnt;
                r_img_din_tready <= 'b0;
            end
    end
 


fifo_clahe_axis_dout fifo_clahe_axis_dout (
  .s_axis_aresetn   ( ~RST                  ), // input wire s_axis_aresetn       
  .s_axis_aclk      ( CLK                   ), // input wire s_axis_aclk                
  .s_axis_tvalid    ( IMG_DIN_TVALID & IMG_DIN_TREADY ), // input wire s_axis_tvalid          
  .s_axis_tready    (                       ), // output wire s_axis_tready         
  .s_axis_tdata     ( IMG_DIN_TDATA         ), // input wire [7 : 0] s_axis_tdata     
  .s_axis_tlast     ( IMG_DIN_TLAST         ), // input wire s_axis_tlast            
  .m_axis_tdata     ( IMG_DOUT_TDATA        ), // output wire [7 : 0] m_axis_tdata          
  .m_axis_tvalid    ( IMG_DOUT_TVALID       ), // output wire m_axis_tvalid         
  .m_axis_tready    ( IMG_DOUT_TREADY       ), // input wire m_axis_tready     
  .m_axis_tlast     ( IMG_DOUT_TLAST        ), // output wire m_axis_tlast            
  .prog_full        ( w_fifo_dout_prog_full )  // output wire prog_full                     
);
    
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
reg  [13:0] r_hist_val_addrb_d; 
reg         r_hist_zero_wr_b;
reg         r_hist_val_dv_b;
wire [17:0] w_hist_val_doutb;
wire [13:0] w_hist_val_doutb_addr = r_hist_val_addrb_d;
wire        w_hist_val_doutb_dv   = r_hist_val_dv_b;

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


integer f_hist = -1;
always @(posedge(CLK))
    begin
        if ( f_hist == -1 )
            f_hist = $fopen("D:/tmp/vivado_sigs/slam_hist.txt");
        else
            if ( w_hist_val_doutb_dv )
                $fwrite(f_hist, "%d\n", w_hist_val_doutb);
    end



// count hist:  
reg               r_img_din_data_dv = 1'b0;
reg               r_img_din_data_dv_d = 1'b0;
//reg               r_img_din_data_dv_dd = 1'b0;
always @(posedge(CLK))
    begin
        r_hist_val_addra    <= (IMG_DIN_TVALID & IMG_DIN_TREADY)? {r_hist_y, r_hist_x, IMG_DIN_TDATA} : r_hist_val_addra; 
        r_img_din_data_dv   <=  IMG_DIN_TVALID & IMG_DIN_TREADY;
        r_img_din_data_dv_d <= r_img_din_data_dv; 
        
        r_hist_val_dina <= w_hist_val_douta + 1'b1;
        r_hist_val_wr_a <= r_img_din_data_dv_d;
         
    end 
    
// read hist:
always @(posedge(CLK))
    begin
        r_hist_val_dv_b <= r_hist_zero_wr_b;
        r_hist_val_addrb_d<= r_hist_val_addrb;
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
    
// clip val and accum excess:
reg  [17:0]         r_clip_thr = PH_CLIP_VAL;
reg  [17:0]         r_hist_val_clipped;
reg                 r_hist_val_clipped_first=1'b0; 
reg  [13:0]         r_hist_val_clipped_addr;
reg                 r_hist_val_clipped_dv;
reg  [PW_IMG+17:0]  r_hist_val_excess = 'b0; 
reg  [17:0]         r_hist_val_add_saved = 'b0;
reg                 r_div_excess_strobe = 1'b0;
always @(posedge(CLK))
    begin
        r_hist_val_clipped_dv   <= w_hist_val_doutb_dv;
        r_hist_val_clipped_addr <= w_hist_val_doutb_addr;
        r_hist_val_clipped_first<= w_hist_val_doutb_dv & (w_hist_val_doutb_addr[PW_IMG-1:0] == 0);
        if ( w_hist_val_doutb_dv )
            begin 
                if ( w_hist_val_doutb > r_clip_thr )
                    begin
                        if ( w_hist_val_doutb_addr[PW_IMG-1:0] == 0 )
                            r_hist_val_excess <= w_hist_val_doutb - r_clip_thr;
                        else
                            r_hist_val_excess <= r_hist_val_excess + w_hist_val_doutb - r_clip_thr;
                    end
                else if ( w_hist_val_doutb_addr[PW_IMG-1:0] == 0 )
                    r_hist_val_excess <= 'b0; 
                    
                if ( w_hist_val_doutb > r_clip_thr )
                    r_hist_val_clipped <= r_clip_thr;
                else
                    r_hist_val_clipped <= w_hist_val_doutb;
            end
        r_div_excess_strobe <= w_hist_val_doutb_dv && (&w_hist_val_doutb_addr[PW_IMG-1:0]) ;
        if ( r_div_excess_strobe )
            begin  
                if ( r_hist_val_excess >= (2**PW_IMG) )
                    r_hist_val_add_saved <= r_hist_val_excess[PW_IMG +: 18]; 
            end 
    end    
    
// delay clipped values while find min of cdf and excess:
localparam LP_DELAY = 256;
reg  [17:0] r_delay_clipped_vals      [0:LP_DELAY-1];
reg         r_delay_clipped_vals_first[0:LP_DELAY-1];
reg         r_delay_clipped_vals_dv   [0:LP_DELAY-1];
wire [17:0] w_delayed_clipped_vals      = r_delay_clipped_vals      [LP_DELAY-1];
wire        w_delayed_clipped_vals_first= r_delay_clipped_vals_first[LP_DELAY-1];
wire        w_delayed_clipped_vals_dv   = r_delay_clipped_vals_dv   [LP_DELAY-1];
always @(posedge(CLK))    
    begin
        r_delay_clipped_vals      <= { r_hist_val_clipped      , r_delay_clipped_vals      [0:LP_DELAY-2]};
        r_delay_clipped_vals_first<= { r_hist_val_clipped_first, r_delay_clipped_vals_first[0:LP_DELAY-2]};
        r_delay_clipped_vals_dv   <= { r_hist_val_clipped_dv   , r_delay_clipped_vals_dv   [0:LP_DELAY-2]};
    end           
    
// find cdf:
reg  [PW_IMG+17:0] r_cdf = 'b0;
reg                r_cdf_dv;
reg                r_cdf_first;
always @(posedge(CLK))
    begin
        r_cdf_dv    <= w_delayed_clipped_vals_dv;
        r_cdf_first <= w_delayed_clipped_vals_first;
        if ( w_delayed_clipped_vals_dv )
            begin
                if ( w_delayed_clipped_vals_first )
                    begin 
                        r_cdf <= w_delayed_clipped_vals + r_hist_val_add_saved; 
                    end
                else
                    begin
                        r_cdf <= r_cdf +  r_hist_val_add_saved + w_delayed_clipped_vals;
                    end
            end
    end    
 
    
// find first non-zero value and sub it form all other values:
reg  [       18:0] r_total_pix = PH_TOTAL_PIX;
reg  [       18:0] r_denom     = 'd1;
reg  [PW_IMG+17:0] r_cdf_min = 'b0;
reg  [PW_IMG+17:0] r_cdf_m = 'b0;
reg                r_cdf_m_dv;
reg                r_cdf_m_first;
always @(posedge(CLK))
    begin
        r_cdf_m_dv    <= r_cdf_dv;
        r_cdf_m_first <= r_cdf_first;
        if ( r_cdf_dv )
            begin
                if ( r_cdf_first ) 
                    begin
                        r_cdf_min <= r_cdf;
                        r_cdf_m   <= 'b0;
                        r_denom   <= r_total_pix - r_cdf;
                    end 
                else
                    begin
                        if ( !r_cdf_min )
                            begin
                                r_cdf_min <= r_cdf;
                                r_cdf_m   <= 'b0;
                                r_denom   <= r_total_pix - r_cdf;
                            end
                        else
                            begin
                                r_cdf_min <= r_cdf_min;
                                r_cdf_m   <= r_cdf - r_cdf_min;
                                r_denom   <= r_total_pix - r_cdf_min;
                            end 
                    end
            end
    end    





wire [PW_IMG+17+PW_IMG:0] w_cdf_255x = {r_cdf_m, 8'b0} - {8'b0, r_cdf_m};
wire [23:0] w_divisor = {5'b0, r_denom};     
wire [39:0] s_axis_dividend_tdata = { {(40-PW_IMG*2-18){1'b0}}, w_cdf_255x};
wire        w_m_div_tvalid;
wire        w_m_div_tfirst;
wire        w_m_div_img_talst;
wire [63:0] w_m_div_tdata ;     
wire [33:0] w_quot = w_m_div_tdata[57:24];
wire [19:0] w_rem  = w_m_div_tdata[19: 0];
cdf_divide cdf_divide (
  .aclk                     ( CLK                   ), // input wire aclk                                                                
  .s_axis_divisor_tvalid    ( r_cdf_m_dv            ), // input wire s_axis_divisor_tvalid            
  .s_axis_divisor_tdata     ( w_divisor             ), // input wire [23 : 0] s_axis_divisor_tdata      
  .s_axis_dividend_tvalid   ( r_cdf_m_dv            ), // input wire s_axis_dividend_tvalid         
  .s_axis_dividend_tlast    ( r_cdf_m_first         ), // input wire s_axis_dividend_tlast            
  .s_axis_dividend_tdata    ( s_axis_dividend_tdata ), // input wire [39 : 0] s_axis_dividend_tdata   
  .m_axis_dout_tvalid       ( w_m_div_tvalid        ), // output wire m_axis_dout_tvalid                    
  .m_axis_dout_tlast        ( w_m_div_tfirst        ), // output wire m_axis_dout_tlast                       
  .m_axis_dout_tdata        ( w_m_div_tdata         )  // output wire [63 : 0] m_axis_dout_tdata              
);    
integer f_cdf = -1;
always @(posedge(CLK))
    begin
        if ( f_cdf == -1 )
            f_cdf = $fopen("D:/tmp/vivado_sigs/slam_cdf.txt");
        else
            if ( w_m_div_tvalid )
                $fwrite(f_cdf, "%d\n",w_quot[31:0]);
    end

// add address info to LUT data:
reg  [ 7:0] r_lut;
reg  [$clog2(P_MAX_TILE-1)*2+PW_IMG-1:0] r_lut_addr = 'b0;
reg         r_lut_dv; 
reg         r_picture_last_d;
always @( posedge(CLK) )
    begin
        r_lut_dv         <= w_m_div_tvalid;
        r_picture_last_d <= w_m_div_img_talst;
        if ( r_picture_last_d )
            begin
                r_lut_addr[PW_IMG +: $clog2(P_MAX_TILE-1)] <= 'b0;
                r_lut_addr[(PW_IMG+ $clog2(P_MAX_TILE-1)) +: $clog2(P_MAX_TILE-1)] <= 'b0; 
            end
        else if ( w_m_div_tvalid )
            begin
                if ( &r_lut_addr[PW_IMG-1:0] )
                    begin
                        if ( r_lut_addr[PW_IMG +: $clog2(P_MAX_TILE-1)] == r_clahe_tiles_minus_one )
                            begin
                                r_lut_addr[PW_IMG +: $clog2(P_MAX_TILE-1)] <= 'b0; 
                                if ( r_lut_addr[(PW_IMG+ $clog2(P_MAX_TILE-1)) +: $clog2(P_MAX_TILE-1)] == r_clahe_tiles_minus_one ) 
                                    r_lut_addr[(PW_IMG+ $clog2(P_MAX_TILE-1)) +: $clog2(P_MAX_TILE-1)] <= 'b0;   
                                else
                                    r_lut_addr[(PW_IMG+ $clog2(P_MAX_TILE-1)) +: $clog2(P_MAX_TILE-1)] <= r_lut_addr[(PW_IMG+ $clog2(P_MAX_TILE-1)) +: $clog2(P_MAX_TILE-1)] + 1'b1;
                            end
                        else
                            r_lut_addr[PW_IMG +: $clog2(P_MAX_TILE-1)] <= r_lut_addr[PW_IMG +: $clog2(P_MAX_TILE-1)] + 1'b1;
                    end
            end
        if ( w_m_div_tvalid )
            begin 
                if ( w_m_div_tfirst )
                    r_lut_addr[PW_IMG-1:0] <= 'b0;
                else  
                    r_lut_addr[PW_IMG-1:0] <= r_lut_addr[PW_IMG-1:0] + 1'b1;
                
                if ( w_quot >= 256 )
                    r_lut <= 'd255;
                else
                    r_lut <= w_quot[7:0];
            end
    end

assign LUT_DOUT      = r_lut;
assign LUT_DOUT_DV   = r_lut_dv;
assign LUT_DOUT_ADDR = r_lut_addr;
    
endmodule
`default_nettype wire
