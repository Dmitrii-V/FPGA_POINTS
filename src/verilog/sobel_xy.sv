`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.05.2026 00:34:32
// Design Name: 
// Module Name: sobel_xy
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
sobel_xy 
#(
    .P_SOBEL_SIZE (  ),
    .P_MAX_W      (  ),
    .P_MAX_H      (  ),
    .PW_IMG       (  ),
    .PW_DOUT      (  ) // +2 - to mul by "-2", +3 - to sum 6 values 
)sobel_xy(
    .CLK              (  ), // input                  
    .RST              (  ), // input                  
    .IMG_DIN_TDATA    (  ), // input  [PW_IMG-1:0]    
    .IMG_DIN_TVALID   (  ), // input                  
    .IMG_DIN_TREADY   (  ), // output                 
    .IMG_DIN_TLAST    (  ), // input                  
    .IXX_DOUT         (  ), // output [PW_DOUT-1:0]   
    .IYY_DOUT         (  ), // output [PW_DOUT-1:0]   
    .IXY_DOUT         (  ), // output [PW_DOUT-1:0]   
    .IXXYYXY_DOUT_DV  (  )  // output                 
    );
*/

module sobel_xy
#(
    parameter P_SOBEL_SIZE =    3,
    parameter P_MAX_W      = 1920,
    parameter P_MAX_H      = 1080,
    parameter PW_IMG       = 8,
    parameter PW_DOUT      = (PW_IMG + 2 + 3)*2  // +2 - to mul by "-2", +3 - to sum 6 values 
)(
    input  wire                 CLK,
    input  wire                 RST,
    
    output wire                 ERROR_WR_ON_APPEND,
    
    input  wire [PW_IMG-1:0]    IMG_DIN_TDATA,
    input  wire                 IMG_DIN_TVALID,
    output wire                 IMG_DIN_TREADY,
    input  wire                 IMG_DIN_TLAST,
     
    output wire [PW_DOUT-1:0]   IXX_DOUT,
    output wire [PW_DOUT-1:0]   IYY_DOUT,
    output wire [PW_DOUT-1:0]   IXY_DOUT,
    output wire                 IXXYYXY_DOUT_DV,
    output wire                 IXXYYXY_DOUT_LAST
    );

assign IMG_DIN_TREADY = 1'b1;

reg  [$clog2(P_MAX_W)-1:0]     r_fifo_cnt;
wire [P_SOBEL_SIZE*PW_IMG-1:0] w_fifo_dout;
wire [P_SOBEL_SIZE*PW_IMG-1:0] w_fifo_din;
wire                           w_fifo_wr;
wire                           w_fifo_rd;
wire                           w_fifo_full;
wire                           w_fifo_empty;


reg  [ 7:0] r_fifo_din_pix    =  'b0;
reg         r_fifo_din_pix_dv = 1'b0;
reg         r_fifo_din_pix_last = 1'b0;
localparam LP_APPEND_LEN = 3*P_MAX_W;
reg  [$clog2(LP_APPEND_LEN)-1:0] r_append_cnt = 'b0;
reg                              r_append_en  = 1'b0;
assign ERROR_WR_ON_APPEND = r_append_en & IMG_DIN_TVALID & IMG_DIN_TREADY;
always @( posedge(CLK) )
    begin
        
        r_fifo_din_pix_dv   <= (IMG_DIN_TVALID & IMG_DIN_TREADY) | r_append_en;
        r_fifo_din_pix_last <= r_append_en  && (r_append_cnt == LP_APPEND_LEN-1);
        if ( IMG_DIN_TVALID & IMG_DIN_TREADY )
            r_fifo_din_pix <= IMG_DIN_TDATA; 
        else
            r_fifo_din_pix <= 'b0; 
            
        if ( IMG_DIN_TVALID & IMG_DIN_TREADY & IMG_DIN_TLAST )
            r_append_en <= 1'b1;
        else if ( r_append_cnt == LP_APPEND_LEN-1 )
            r_append_en <= 1'b0;
        if ( IMG_DIN_TVALID & IMG_DIN_TREADY & IMG_DIN_TLAST )
            r_append_cnt <= 'b0;
        else if ( r_append_cnt < LP_APPEND_LEN )
            r_append_cnt <= r_append_cnt + 1'b1; 
            
    end

assign w_fifo_wr = r_fifo_din_pix_dv;
assign w_fifo_rd = w_fifo_wr & ( r_fifo_cnt == (P_MAX_W) );
assign w_fifo_din = {w_fifo_dout[15:0], r_fifo_din_pix};
wire   w_fifo_rd_last = r_fifo_din_pix_last;
fifo_conv_few_lines fifo_conv_few_lines (
  .clk      ( CLK          ), // input wire clk                 
  .srst     ( RST          ), // input wire srst             
  .din      ( w_fifo_din   ), // input wire [23 : 0] din       
  .wr_en    ( w_fifo_wr    ), // input wire wr_en          
  .rd_en    ( w_fifo_rd    ), // input wire rd_en          
  .dout     ( w_fifo_dout  ), // output wire [23 : 0] dout   
  .full     ( w_fifo_full  ), // output wire full            
  .empty    ( w_fifo_empty )  // output wire empty         
); 

always @( posedge(CLK) )
    begin
        if ( RST )
            r_fifo_cnt <= 'b0;
        else
            begin
                case ( {w_fifo_wr, w_fifo_rd} )
                    2'b00 : r_fifo_cnt <= r_fifo_cnt;
                    2'b01 : r_fifo_cnt <= r_fifo_cnt - 1'b1;
                    2'b10 : r_fifo_cnt <= r_fifo_cnt + 1'b1;
                    2'b11 : r_fifo_cnt <= r_fifo_cnt;
                endcase 
            end
    end


    
reg [PW_IMG-1:0] r_regs [0:P_SOBEL_SIZE-1][0:P_SOBEL_SIZE-1];    
reg              r_regs_dv = 1'b0;
reg              r_regs_last = 1'b0;
  
initial begin
    for (integer ii = 0; ii < P_SOBEL_SIZE; ii = ii + 1 )
        begin
            for (integer ji = 0; ji < P_SOBEL_SIZE; ji = ji + 1 )
                begin
                    r_regs[ii][ji] = 0;
                end 
        end
end


// shift data from Fifo to REGS:
always @( posedge(CLK) )
    begin
        r_regs_dv   <= w_fifo_rd;
        r_regs_last <= w_fifo_rd_last;
        if ( w_fifo_rd )
            begin
                for ( integer i = 0; i < P_SOBEL_SIZE; i = i + 1 )
                    begin
                        r_regs[i][0] <= w_fifo_dout[i*PW_IMG +: PW_IMG];
                        for ( integer j = 1; j < P_SOBEL_SIZE; j = j + 1 )
                            r_regs[i][j] <= r_regs[i][j-1];  
                    end
            end
    end    


// ADD ALL VALUES IN REGS TO GET Ix and Iy:
localparam LPW_ADD_TREE_IN  = PW_IMG+2;
localparam LPW_ADD_TREE_OUT = PW_IMG+2+3;

wire w_adder_tree_dout_xy_dv   = r_regs_dv; // temporary!
wire w_adder_tree_dout_xy_last = r_regs_last; // temporary!
// find  Sobel X:
wire [LPW_ADD_TREE_IN-1 :0] w_adder_tree_din_x [0 : P_SOBEL_SIZE*P_SOBEL_SIZE-1];
wire [LPW_ADD_TREE_OUT-1:0] w_adder_tree_dout_x;
assign w_adder_tree_din_x[0] = -$signed({2'b0, r_regs[0][0]}      ); // x -1
assign w_adder_tree_din_x[1] = 'b0;//-$signed({2'b0, r_regs[0][1]}); // x  0
assign w_adder_tree_din_x[2] =  $signed({2'b0, r_regs[0][2]}      ); // x  1
assign w_adder_tree_din_x[3] = -$signed({1'b0, r_regs[1][0], 1'b0}); // x -2
assign w_adder_tree_din_x[4] = 'b0;//-$signed({2'b0, r_regs[1][1]}); // x  0
assign w_adder_tree_din_x[5] =  $signed({1'b0, r_regs[1][2], 1'b0}); // x  2
assign w_adder_tree_din_x[6] = -$signed({2'b0, r_regs[2][0]}      ); // x -1
assign w_adder_tree_din_x[7] = 'b0;//-$signed({2'b0, r_regs[2][1]}); // x  0
assign w_adder_tree_din_x[8] =  $signed({2'b0, r_regs[2][2]}      ); // x  1 


// find  Sobel Y:
wire [LPW_ADD_TREE_IN-1 :0] w_adder_tree_din_y [0 : P_SOBEL_SIZE*P_SOBEL_SIZE-1];
wire [LPW_ADD_TREE_OUT-1:0] w_adder_tree_dout_y;
assign w_adder_tree_din_y[0] = -$signed({2'b0, r_regs[0][0]}      ); // x  1
assign w_adder_tree_din_y[1] = -$signed({1'b0, r_regs[0][1], 1'b0}); // x  2
assign w_adder_tree_din_y[2] = -$signed({2'b0, r_regs[0][2]}      ); // x  1
assign w_adder_tree_din_y[3] = 'b0;// $signed({2'b0, r_regs[1][0]}); // x  0
assign w_adder_tree_din_y[4] = 'b0;// $signed({2'b0, r_regs[1][1]}); // x  0
assign w_adder_tree_din_y[5] = 'b0;// $signed({2'b0, r_regs[1][2]}); // x  0
assign w_adder_tree_din_y[6] =  $signed({2'b0, r_regs[2][0]}      ); // x  1
assign w_adder_tree_din_y[7] =  $signed({1'b0, r_regs[2][1], 1'b0}); // x  2
assign w_adder_tree_din_y[8] =  $signed({2'b0, r_regs[2][2]}      ); // x  1 


assign w_adder_tree_dout_x = { {3{w_adder_tree_din_x[0][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[0]} +
                             { {3{w_adder_tree_din_x[1][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[1]} +
                             { {3{w_adder_tree_din_x[2][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[2]} +
                             { {3{w_adder_tree_din_x[3][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[3]} +
                             { {3{w_adder_tree_din_x[4][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[4]} +
                             { {3{w_adder_tree_din_x[5][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[5]} +
                             { {3{w_adder_tree_din_x[6][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[6]} +
                             { {3{w_adder_tree_din_x[7][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[7]} +
                             { {3{w_adder_tree_din_x[8][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_x[8]};
    
assign w_adder_tree_dout_y = { {3{w_adder_tree_din_y[0][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[0]} +
                             { {3{w_adder_tree_din_y[1][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[1]} +
                             { {3{w_adder_tree_din_y[2][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[2]} +
                             { {3{w_adder_tree_din_y[3][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[3]} +
                             { {3{w_adder_tree_din_y[4][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[4]} +
                             { {3{w_adder_tree_din_y[5][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[5]} +
                             { {3{w_adder_tree_din_y[6][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[6]} +
                             { {3{w_adder_tree_din_y[7][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[7]} +
                             { {3{w_adder_tree_din_y[8][LPW_ADD_TREE_IN-1]}}, w_adder_tree_din_y[8]};


reg  [LPW_ADD_TREE_OUT-1:0] r_adder_tree_dout_x;
reg  [LPW_ADD_TREE_OUT-1:0] r_adder_tree_dout_y;
reg                         r_adder_tree_dout_dv;
reg                         r_adder_tree_dout_last;
reg  [31:0]                 r_dbg_cnt = 'b0;
always @(posedge(CLK))
    begin
        r_adder_tree_dout_x    <= w_adder_tree_dout_x;
        r_adder_tree_dout_y    <= w_adder_tree_dout_y;
        r_adder_tree_dout_dv   <= w_adder_tree_dout_xy_dv;
        r_adder_tree_dout_last <= w_adder_tree_dout_xy_last;
        
        if ( w_adder_tree_dout_xy_dv )
            r_dbg_cnt <= r_dbg_cnt + 1;
    end


integer f_sobel = -1;
always @(posedge(CLK))
    begin
        if ( f_sobel == -1 )
            f_sobel = $fopen("D:/tmp/vivado_sigs/sobel_ix_iy.txt");
        else
            begin
                if ( r_adder_tree_dout_dv )
                    $fwrite(f_sobel, "%d %d\n", $signed(r_adder_tree_dout_x), $signed(r_adder_tree_dout_y) );
            end
            
    end


// Perform multiplication:
wire [LPW_ADD_TREE_OUT*2-1:0] w_ixx;
wire [LPW_ADD_TREE_OUT*2-1:0] w_iyy;
wire [LPW_ADD_TREE_OUT*2-1:0] w_ixy;
wire                          w_i_xx_yy_xy_dv;
wire                          w_i_xx_yy_xy_last;
sobel_mul_xx_yy_xy mul_xx (
  .CLK  ( CLK                 ), // input wire CLK         
  .A    ( r_adder_tree_dout_x ), // input wire [12 : 0] A      
  .B    ( r_adder_tree_dout_x ), // input wire [12 : 0] B      
  .P    ( w_ixx               )  // output wire [25 : 0] P     
);
sobel_mul_xx_yy_xy mul_yy (
  .CLK  ( CLK                 ), // input wire CLK         
  .A    ( r_adder_tree_dout_y ), // input wire [12 : 0] A      
  .B    ( r_adder_tree_dout_y ), // input wire [12 : 0] B      
  .P    ( w_iyy               )  // output wire [25 : 0] P     
);
sobel_mul_xx_yy_xy mul_xy (
  .CLK  ( CLK                 ), // input wire CLK         
  .A    ( r_adder_tree_dout_x ), // input wire [12 : 0] A      
  .B    ( r_adder_tree_dout_y ), // input wire [12 : 0] B      
  .P    ( w_ixy               )  // output wire [25 : 0] P     
);

localparam LP_DM = 3;
reg r_delay_dv [0 : LP_DM-1];
assign w_i_xx_yy_xy_dv = r_delay_dv[LP_DM-1];
reg r_delay_last [0 : LP_DM-1];
assign w_i_xx_yy_xy_last = r_delay_last[LP_DM-1];
always @( posedge(CLK) )
    r_delay_dv <= {r_adder_tree_dout_dv, r_delay_dv[0:LP_DM-2]};
always @( posedge(CLK) )
    r_delay_last <= {r_adder_tree_dout_last, r_delay_last[0:LP_DM-2]};
        
reg [$clog2(P_MAX_W*P_MAX_H)-1:0] r_dout_cnt = 'b0;     
always @( posedge(CLK) )
    begin
        if ( RST )
            r_dout_cnt <= 'b0;
        else if ( w_i_xx_yy_xy_dv )
            r_dout_cnt <= r_dout_cnt + 1'b1; 
    end
assign IXX_DOUT          = w_ixx;      
assign IYY_DOUT          = w_iyy;
assign IXY_DOUT          = w_ixy;
assign IXXYYXY_DOUT_DV   = w_i_xx_yy_xy_dv && (r_dout_cnt > (P_MAX_W-1));  
assign IXXYYXY_DOUT_LAST = w_i_xx_yy_xy_last && (r_dout_cnt > (P_MAX_W-1));  
    
endmodule
`default_nettype wire 
