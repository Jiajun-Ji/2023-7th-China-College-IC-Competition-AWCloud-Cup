module bilinear_interpolation
#(
    parameter C_SRC_IMG_WIDTH  = 11'd400    ,//输入灰度图h
    parameter C_SRC_IMG_HEIGHT = 11'd320    ,//输入灰度图wh
    parameter C_DST_IMG_WIDTH  = 11'd300   ,//输出灰度图h
    parameter C_DST_IMG_HEIGHT = 11'd300    ,//输出灰度图w
    parameter C_X_RATIO        = 17'd87381  ,//该值使用如下式子计算：floor(C_SRC_IMG_WIDTH/C_DST_IMG_WIDTH*2^16)
    parameter C_Y_RATIO        = 17'd69905   //该值使用如下式子计算：floor(C_SRC_IMG_HEIGHT/C_DST_IMG_HEIGHT*2^16)
)
(
    input  wire                 clk_in1         ,
    input  wire                 clk_in2         ,
    input  wire                 rst_n           ,
    
    //  Image data prepared to be processed
    input  wire                 per_img_vsync1   ,       // 输入图像场同步信号
    input  wire                 per_img_href    ,       //  输入图像行同步信号
    input  wire     [7:0]       per_img_gray    ,       //  输入灰度像素
    
    //  Image data has been processed
    output wire                 post_img_vsync1  ,       // 处理后的图像场同步信号
    output reg                  post_img_href   ,       //  处理后的图像行同步信号
    output reg      [7:0]       post_img_gray           //  处理后的图像灰度像素输出
);

//----------------------------------------------------------------------
//将输入输出场同步信号取反
reg                             post_img_vsync;
wire                             per_img_vsync;
assign per_img_vsync=~per_img_vsync1;
assign post_img_vsync1=~post_img_vsync;

//----------------------------------------------------------------------
//生成输入输出行同步信号的下降沿
reg                             per_img_href_dly;
reg                             post_img_href_dly;
always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        per_img_href_dly <= 1'b0;
    else
        per_img_href_dly <= per_img_href;
end


always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        post_img_href_dly <= 1'b0;
    else
        post_img_href_dly <= post_img_href;
end

//----------------------------------------------------------------------
//计数输入输出是否正确
wire                            per_img_href_neg;
wire                            post_img_href_neg;
reg             [10:0]          img_vs_cnt;                             //  from 0 to C_SRC_IMG_HEIGHT - 1
reg             [10:0]          img_hs_cnt;                             //  from 0 to C_SRC_IMG_WIDTH - 1
reg             [10:0]          post_img_vs_cnt;                             //  from 0 to C_DST_IMG_WIDTH - 1
reg             [10:0]          post_img_hs_cnt;                             //  from 0 to C_DST_IMG_HEIGHT - 1

assign per_img_href_neg = per_img_href_dly & ~per_img_href;//未处理图像的上升沿
assign post_img_href_neg = post_img_href_dly & ~post_img_href;//处理图像的上升沿


//计数输出是否正确
//计数一帧中有多少个行同步
always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        post_img_vs_cnt <= 11'b0;
    else
    begin
        if(post_img_vsync == 1'b0)
            post_img_vs_cnt <= 11'b0;
        else
        begin
            if(post_img_href_neg == 1'b1)
                post_img_vs_cnt <= post_img_vs_cnt + 1'b1;
            else
                post_img_vs_cnt <= post_img_vs_cnt;
        end
    end
end

//计数一个行同步中有多少个像素
always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        post_img_hs_cnt<= 11'b0;
    else
    begin
        if((post_img_vsync == 1'b1)&&(post_img_href == 1'b1))
            post_img_hs_cnt <= post_img_hs_cnt + 1'b1;
        else
            post_img_hs_cnt <= 11'b0;
    end
end

//计数输入是否正确
always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        img_vs_cnt <= 11'b0;
    else
    begin
        if(per_img_vsync == 1'b0)
            img_vs_cnt <= 11'b0;
        else
        begin
            if(per_img_href_neg == 1'b1)
                img_vs_cnt <= img_vs_cnt + 1'b1;
            else
                img_vs_cnt <= img_vs_cnt;
        end
    end
end

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        img_hs_cnt <= 11'b0;
    else
    begin
        if((per_img_vsync == 1'b1)&&(per_img_href == 1'b1))
            img_hs_cnt <= img_hs_cnt + 1'b1;
        else
            img_hs_cnt <= 11'b0;
    end
end


//----------------------------------------------------------------------
//读写控制信号生成
reg             [7:0]           bram_a_wdata;

always @(posedge clk_in1)
begin
    bram_a_wdata <= per_img_gray;
end

reg             [11:0]          bram_a_waddr;

always @(posedge clk_in1)
begin
    bram_a_waddr <= {img_vs_cnt[2:1],10'b0} + img_hs_cnt;
end

reg                             bram1_a_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        bram1_a_wenb <= 1'b0;
    else
        bram1_a_wenb <= per_img_vsync & per_img_href & ~img_vs_cnt[0];
end

reg                             bram2_a_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        bram2_a_wenb <= 1'b0;
    else
        bram2_a_wenb <= per_img_vsync & per_img_href & img_vs_cnt[0];
end

reg             [10:0]          fifo_wdata;

always @(posedge clk_in1)
begin
    fifo_wdata <= img_vs_cnt;
end

reg                             fifo_wenb;

always @(posedge clk_in1)
begin
    if(rst_n == 1'b0)
        fifo_wenb <= 1'b0;
    else
    begin
        if((per_img_vsync == 1'b1)&&(per_img_href == 1'b1)&&(img_hs_cnt == C_SRC_IMG_WIDTH - 1'b1))
            fifo_wenb <= 1'b1;
        else
            fifo_wenb <= 1'b0;
    end
end

//----------------------------------------------------------------------
//例化4个dram以及fifo
//  bram & fifo rw
reg             [11:0]          even_bram1_b_raddr;
reg             [11:0]          odd_bram1_b_raddr;
reg             [11:0]          even_bram2_b_raddr;
reg             [11:0]          odd_bram2_b_raddr;
wire            [ 7:0]          even_bram1_b_rdata;
wire            [ 7:0]          odd_bram1_b_rdata;
wire            [ 7:0]          even_bram2_b_rdata;
wire            [ 7:0]          odd_bram2_b_rdata;

bram_ture_dual_port
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8 )
)
u0_image_data_bram1
(
    .clka   (clk_in1            ),
    .wea    (bram1_a_wenb       ),
    .addra  (bram_a_waddr       ),
    .dina   (bram_a_wdata       ),
    .douta  (                   ),
    .clkb   (clk_in2            ),
    .web    (1'b0               ),
    .addrb  (even_bram1_b_raddr ),
    .dinb   (8'b0               ),
    .doutb  (even_bram1_b_rdata )
);

bram_ture_dual_port
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8 )
)
u1_image_data_bram1
(
    .clka   (clk_in1            ),
    .wea    (bram1_a_wenb       ),
    .addra  (bram_a_waddr       ),
    .dina   (bram_a_wdata       ),
    .douta  (                   ),
    .clkb   (clk_in2            ),
    .web    (1'b0               ),
    .addrb  (odd_bram1_b_raddr  ),
    .dinb   (8'b0               ),
    .doutb  (odd_bram1_b_rdata  )
);

bram_ture_dual_port
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8 )
)
u2_image_data_bram2
(
    .clka   (clk_in1            ),
    .wea    (bram2_a_wenb       ),
    .addra  (bram_a_waddr       ),
    .dina   (bram_a_wdata       ),
    .douta  (                   ),
    .clkb   (clk_in2            ),
    .web    (1'b0               ),
    .addrb  (even_bram2_b_raddr ),
    .dinb   (8'b0               ),
    .doutb  (even_bram2_b_rdata )
);

bram_ture_dual_port
#(
    .C_ADDR_WIDTH(12),
    .C_DATA_WIDTH(8 )
)
u3_image_data_bram2
(
    .clka   (clk_in1            ),
    .wea    (bram2_a_wenb       ),
    .addra  (bram_a_waddr       ),
    .dina   (bram_a_wdata       ),
    .douta  (                   ),
    .clkb   (clk_in2            ),
    .web    (1'b0               ),
    .addrb  (odd_bram2_b_raddr  ),
    .dinb   (8'b0               ),
    .doutb  (odd_bram2_b_rdata  )
);

wire                            fifo_renb;
wire            [10:0]          fifo_rdata;
wire                            fifo_empty;
wire                            fifo_full;

asyn_fifo
#(
    .C_DATA_WIDTH       (11),
    .C_FIFO_DEPTH_WIDTH (4 )
)
u_tag_fifo
(
    .wr_rst_n   (rst_n      ),
    .wr_clk     (clk_in1    ),
    .wr_en      (fifo_wenb  ),
    .wr_data    (fifo_wdata ),
    .wr_full    (fifo_full  ),
    .wr_cnt     (           ),
    .rd_rst_n   (rst_n      ),
    .rd_clk     (clk_in2    ),
    .rd_en      (fifo_renb  ),
    .rd_data    (fifo_rdata ),
    .rd_empty   (fifo_empty ),
    .rd_cnt     (           )
);

//----------------------------------------------------------------------
//控制状态机
localparam S_IDLE      = 3'd0;//
localparam S_Y_LOAD    = 3'd1;
localparam S_BRAM_ADDR = 3'd2;
localparam S_Y_INC     = 3'd3;
localparam S_RD_FIFO   = 3'd4;

reg             [ 2:0]          state;
reg             [26:0]          y_dec;
reg             [26:0]          x_dec;
reg             [10:0]          y_cnt;
reg             [10:0]          x_cnt;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        state <= S_IDLE;
    else
    begin
        case(state)
            S_IDLE : 
            begin
                if(fifo_empty == 1'b0)
                begin
                    if((fifo_rdata != 11'b0)&&(y_cnt == C_DST_IMG_HEIGHT))
                        state <= S_RD_FIFO;
                    else
                        state <= S_Y_LOAD;
                end
                else
                    state <= S_IDLE;
            end
            S_Y_LOAD : 
            begin
                if((y_dec[26:16] + 1'b1 <= fifo_rdata)||(y_cnt == C_DST_IMG_HEIGHT - 1'b1))
                    state <= S_BRAM_ADDR;
                else
                    state <= S_RD_FIFO;
            end
            S_BRAM_ADDR : 
            begin
                if(x_cnt == C_DST_IMG_WIDTH - 1'b1)
                    state <= S_Y_INC;
                else
                    state <= S_BRAM_ADDR;
            end
            S_Y_INC : 
            begin
                if(y_cnt == C_DST_IMG_HEIGHT - 1'b1)
                    state <= S_RD_FIFO;
                else
                    state <= S_Y_LOAD;
            end
            S_RD_FIFO : 
            begin
                state <= S_IDLE;
            end
            default : 
            begin
                state <= S_IDLE;
            end
        endcase
    end
end

assign fifo_renb = (state == S_RD_FIFO) ? 1'b1 : 1'b0;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        y_dec <= 27'b0;
    else
    begin
        if((state == S_IDLE)&&(fifo_empty == 1'b0)&&(fifo_rdata == 11'b0))
            y_dec <= 27'b0;
        else if(state == S_Y_INC)
            y_dec <= y_dec + C_Y_RATIO;
        else
            y_dec <= y_dec;
    end
end

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        y_cnt <= 11'b0;
    else
    begin
        if((state == S_IDLE)&&(fifo_empty == 1'b0)&&(fifo_rdata == 11'b0))
            y_cnt <= 11'b0;
        else if(state == S_Y_INC)
            y_cnt <= y_cnt + 1'b1;
        else
            y_cnt <= y_cnt;
    end
end

always @(posedge clk_in2)
begin
    if(state == S_BRAM_ADDR)
        x_dec <= x_dec + C_X_RATIO;
    else
        x_dec <= 27'b0;
end

always @(posedge clk_in2)
begin
    if(state == S_BRAM_ADDR)
        x_cnt <= x_cnt + 1'b1;
    else
        x_cnt <= 11'b0;
end

//----------------------------------------------------------------------
//  c1打拍
reg                             img_vs_c1;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        img_vs_c1 <= 1'b0;
    else
    begin
        if((state == S_BRAM_ADDR)&&(x_cnt == 11'b0)&&(y_cnt == 11'b0))
            img_vs_c1 <= 1'b1;
        else if((state == S_Y_INC)&&(y_cnt == C_DST_IMG_HEIGHT - 1'b1))
            img_vs_c1 <= 1'b0;
        else
            img_vs_c1 <= img_vs_c1;
    end
end

reg                             img_hs_c1;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
        img_hs_c1 <= 1'b0;
    else
    begin
        if(state == S_BRAM_ADDR)
            img_hs_c1 <= 1'b1;
        else
            img_hs_c1 <= 1'b0;
    end
end

reg             [10:0]          x_int_c1;
reg             [10:0]          y_int_c1;
reg             [16:0]          x_fra_c1;
reg             [16:0]          inv_x_fra_c1;
reg             [16:0]          y_fra_c1;
reg             [16:0]          inv_y_fra_c1;

always @(posedge clk_in2)
begin
    x_int_c1     <= x_dec[25:16];
    y_int_c1     <= y_dec[25:16];
    x_fra_c1     <= {1'b0,x_dec[15:0]};
    inv_x_fra_c1 <= 17'h10000 - {1'b0,x_dec[15:0]};
    y_fra_c1     <= {1'b0,y_dec[15:0]};
    inv_y_fra_c1 <= 17'h10000 - {1'b0,y_dec[15:0]};
end

//----------------------------------------------------------------------
//  c2
reg                             img_vs_c2;
reg                             img_hs_c2;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c2 <= 1'b0;
        img_hs_c2 <= 1'b0;
    end
    else
    begin
        img_vs_c2 <= img_vs_c1;
        img_hs_c2 <= img_hs_c1;
    end
end

reg             [11:0]          bram_addr_c2;
reg             [33:0]          frac_00_c2;
reg             [33:0]          frac_01_c2;
reg             [33:0]          frac_10_c2;
reg             [33:0]          frac_11_c2;
reg                             bram_mode_c2;

always @(posedge clk_in2)
begin
    bram_addr_c2 <= {y_int_c1[2:1],10'b0} + x_int_c1;
    frac_00_c2   <= inv_x_fra_c1 * inv_y_fra_c1;
    frac_01_c2   <= x_fra_c1 * inv_y_fra_c1;
    frac_10_c2   <= inv_x_fra_c1 * y_fra_c1;
    frac_11_c2   <= x_fra_c1 * y_fra_c1;
    bram_mode_c2 <= y_int_c1[0];
end

reg                             right_pixel_extand_flag_c2;
reg                             bottom_pixel_extand_flag_c2;

always @(posedge clk_in2)
begin
    if(x_int_c1 == C_SRC_IMG_WIDTH - 1'b1)
        right_pixel_extand_flag_c2 <= 1'b1;
    else
        right_pixel_extand_flag_c2 <= 1'b0;
    if(y_int_c1 == C_SRC_IMG_HEIGHT - 1'b1)
        bottom_pixel_extand_flag_c2 <= 1'b1;
    else
        bottom_pixel_extand_flag_c2 <= 1'b0;
end

//----------------------------------------------------------------------
//  c3
reg                             img_vs_c3;
reg                             img_hs_c3;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c3 <= 1'b0;
        img_hs_c3 <= 1'b0;
    end
    else
    begin
        img_vs_c3 <= img_vs_c2;
        img_hs_c3 <= img_hs_c2;
    end
end

always @(posedge clk_in2)
begin
    if(bram_mode_c2 == 1'b0)
    begin
        even_bram1_b_raddr <= bram_addr_c2;
        odd_bram1_b_raddr  <= bram_addr_c2 + 1'b1;
        even_bram2_b_raddr <= bram_addr_c2;
        odd_bram2_b_raddr  <= bram_addr_c2 + 1'b1;
    end
    else
    begin
        even_bram1_b_raddr <= bram_addr_c2 + 11'd1024;
        odd_bram1_b_raddr  <= bram_addr_c2 + 11'd1025;
        even_bram2_b_raddr <= bram_addr_c2;
        odd_bram2_b_raddr  <= bram_addr_c2 + 1'b1;
    end
end

reg             [33:0]          frac_00_c3;
reg             [33:0]          frac_01_c3;
reg             [33:0]          frac_10_c3;
reg             [33:0]          frac_11_c3;
reg                             bram_mode_c3;
reg                             right_pixel_extand_flag_c3;
reg                             bottom_pixel_extand_flag_c3;

always @(posedge clk_in2)
begin
    frac_00_c3                  <= frac_00_c2;
    frac_01_c3                  <= frac_01_c2;
    frac_10_c3                  <= frac_10_c2;
    frac_11_c3                  <= frac_11_c2;
    bram_mode_c3                <= bram_mode_c2;
    right_pixel_extand_flag_c3  <= right_pixel_extand_flag_c2;
    bottom_pixel_extand_flag_c3 <= bottom_pixel_extand_flag_c2;
end

//----------------------------------------------------------------------
//  c4
reg                             img_vs_c4;
reg                             img_hs_c4;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c4 <= 1'b0;
        img_hs_c4 <= 1'b0;
    end
    else
    begin
        img_vs_c4 <= img_vs_c3;
        img_hs_c4 <= img_hs_c3;
    end
end

reg             [33:0]          frac_00_c4;
reg             [33:0]          frac_01_c4;
reg             [33:0]          frac_10_c4;
reg             [33:0]          frac_11_c4;
reg                             bram_mode_c4;
reg                             right_pixel_extand_flag_c4;
reg                             bottom_pixel_extand_flag_c4;

always @(posedge clk_in2)
begin
    frac_00_c4                  <= frac_00_c3;
    frac_01_c4                  <= frac_01_c3;
    frac_10_c4                  <= frac_10_c3;
    frac_11_c4                  <= frac_11_c3;
    bram_mode_c4                <= bram_mode_c3;
    right_pixel_extand_flag_c4  <= right_pixel_extand_flag_c3;
    bottom_pixel_extand_flag_c4 <= bottom_pixel_extand_flag_c3;
end

//----------------------------------------------------------------------
//  c5
reg                             img_vs_c5;
reg                             img_hs_c5;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c5 <= 1'b0;
        img_hs_c5 <= 1'b0;
    end
    else
    begin
        img_vs_c5 <= img_vs_c4;
        img_hs_c5 <= img_hs_c4;
    end
end

reg             [7:0]           pixel_data00_c5;
reg             [7:0]           pixel_data01_c5;
reg             [7:0]           pixel_data10_c5;
reg             [7:0]           pixel_data11_c5;

always @(posedge clk_in2)
begin
    if(bram_mode_c4 == 1'b0)
    begin
        pixel_data00_c5 <= even_bram1_b_rdata;
        pixel_data01_c5 <= odd_bram1_b_rdata;
        pixel_data10_c5 <= even_bram2_b_rdata;
        pixel_data11_c5 <= odd_bram2_b_rdata;
    end
    else
    begin
        pixel_data00_c5 <= even_bram2_b_rdata;
        pixel_data01_c5 <= odd_bram2_b_rdata;
        pixel_data10_c5 <= even_bram1_b_rdata;
        pixel_data11_c5 <= odd_bram1_b_rdata;
    end
end

reg             [33:0]          frac_00_c5;
reg             [33:0]          frac_01_c5;
reg             [33:0]          frac_10_c5;
reg             [33:0]          frac_11_c5;
reg                             right_pixel_extand_flag_c5;
reg                             bottom_pixel_extand_flag_c5;

always @(posedge clk_in2)
begin
    frac_00_c5                  <= frac_00_c4;
    frac_01_c5                  <= frac_01_c4;
    frac_10_c5                  <= frac_10_c4;
    frac_11_c5                  <= frac_11_c4;
    right_pixel_extand_flag_c5  <= right_pixel_extand_flag_c4;
    bottom_pixel_extand_flag_c5 <= bottom_pixel_extand_flag_c4;
end

//----------------------------------------------------------------------
//  c6
reg                             img_vs_c6;
reg                             img_hs_c6;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c6 <= 1'b0;
        img_hs_c6 <= 1'b0;
    end
    else
    begin
        img_vs_c6 <= img_vs_c5;
        img_hs_c6 <= img_hs_c5;
    end
end

reg             [7:0]           pixel_data00_c6;
reg             [7:0]           pixel_data01_c6;
reg             [7:0]           pixel_data10_c6;
reg             [7:0]           pixel_data11_c6;

always @(posedge clk_in2)
begin
    case({right_pixel_extand_flag_c5,bottom_pixel_extand_flag_c5})
        2'b00 : 
        begin
            pixel_data00_c6 <= pixel_data00_c5;
            pixel_data01_c6 <= pixel_data01_c5;
            pixel_data10_c6 <= pixel_data10_c5;
            pixel_data11_c6 <= pixel_data11_c5;
        end
        2'b01 : 
        begin
            pixel_data00_c6 <= pixel_data00_c5;
            pixel_data01_c6 <= pixel_data01_c5;
            pixel_data10_c6 <= pixel_data00_c5;
            pixel_data11_c6 <= pixel_data01_c5;
        end
        2'b10 : 
        begin
            pixel_data00_c6 <= pixel_data00_c5;
            pixel_data01_c6 <= pixel_data00_c5;
            pixel_data10_c6 <= pixel_data10_c5;
            pixel_data11_c6 <= pixel_data10_c5;
        end
        2'b11 : 
        begin
            pixel_data00_c6 <= pixel_data00_c5;
            pixel_data01_c6 <= pixel_data00_c5;
            pixel_data10_c6 <= pixel_data00_c5;
            pixel_data11_c6 <= pixel_data00_c5;
        end
    endcase
end

reg             [33:0]          frac_00_c6;
reg             [33:0]          frac_01_c6;
reg             [33:0]          frac_10_c6;
reg             [33:0]          frac_11_c6;

always @(posedge clk_in2)
begin
    frac_00_c6 <= frac_00_c5;
    frac_01_c6 <= frac_01_c5;
    frac_10_c6 <= frac_10_c5;
    frac_11_c6 <= frac_11_c5;
end

//----------------------------------------------------------------------
//  c7
reg                             img_vs_c7;
reg                             img_hs_c7;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c7 <= 1'b0;
        img_hs_c7 <= 1'b0;
    end
    else
    begin
        img_vs_c7 <= img_vs_c6;
        img_hs_c7 <= img_hs_c6;
    end
end

reg             [41:0]          gray_data00_c7;
reg             [41:0]          gray_data01_c7;
reg             [41:0]          gray_data10_c7;
reg             [41:0]          gray_data11_c7;

always @(posedge clk_in2)
begin
    gray_data00_c7 <= frac_00_c6 * pixel_data00_c6;
    gray_data01_c7 <= frac_01_c6 * pixel_data01_c6;
    gray_data10_c7 <= frac_10_c6 * pixel_data10_c6;
    gray_data11_c7 <= frac_11_c6 * pixel_data11_c6;
end

//----------------------------------------------------------------------
//  c8
reg                             img_vs_c8;
reg                             img_hs_c8;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c8 <= 1'b0;
        img_hs_c8 <= 1'b0;
    end
    else
    begin
        img_vs_c8 <= img_vs_c7;
        img_hs_c8 <= img_hs_c7;
    end
end

reg             [42:0]          gray_data_tmp1_c8;
reg             [42:0]          gray_data_tmp2_c8;

always @(posedge clk_in2)
begin
    gray_data_tmp1_c8 <= gray_data00_c7 + gray_data01_c7;
    gray_data_tmp2_c8 <= gray_data10_c7 + gray_data11_c7;
end

//----------------------------------------------------------------------
//  c9
reg                             img_vs_c9;
reg                             img_hs_c9;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c9 <= 1'b0;
        img_hs_c9 <= 1'b0;
    end
    else
    begin
        img_vs_c9 <= img_vs_c8;
        img_hs_c9 <= img_hs_c8;
    end
end

reg             [43:0]          gray_data_c9;

always @(posedge clk_in2)
begin
    gray_data_c9 <= gray_data_tmp1_c8 + gray_data_tmp2_c8;
end

//----------------------------------------------------------------------
//  c10
reg                             img_vs_c10;
reg                             img_hs_c10;

always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        img_vs_c10 <= 1'b0;
        img_hs_c10 <= 1'b0;
    end
    else
    begin
        img_vs_c10 <= img_vs_c9;
        img_hs_c10 <= img_hs_c9;
    end
end

reg             [11:0]          gray_data_c10;

always @(posedge clk_in2)
begin
    gray_data_c10 <= gray_data_c9[43:32] + gray_data_c9[31];
end

//----------------------------------------------------------------------
//  信号输出
always @(posedge clk_in2)
begin
    if(rst_n == 1'b0)
    begin
        post_img_vsync <= 1'b0;
        post_img_href  <= 1'b0;
    end
    else
    begin
        post_img_vsync <= img_vs_c10;
        post_img_href  <= img_hs_c10;
    end
end

always @(posedge clk_in2)
begin
    if(gray_data_c10 > 12'd255)
        post_img_gray <= 8'd255;
    else
        post_img_gray <= gray_data_c10[7:0];
end






endmodule