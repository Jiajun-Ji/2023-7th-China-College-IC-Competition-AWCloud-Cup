module  resize_top
#(
//参数
	parameter USER_DATA_WIDTH = 32		//输出位宽32
)
(
    input   wire            sys_rst_n       ,   //复位信号
// 输入dvp时序
    input   wire            dvp_pclk_in     ,   //输入摄像头像素时钟
    input   wire            dvp_href_in     ,   //输入摄像头行同步信号
    input   wire            dvp_vsync_in    ,   //输入摄像头场同步信号
    input   wire    [ 7:0]  dvp_data_in     ,   //输入摄像头图像数据
// 输出dvp时钟
	output  wire            resize_pclk,   //场同步开始
// 写FIFO
    output  wire            resize_wr_en    ,   //图像数据有效使能信号
    output  wire    [USER_DATA_WIDTH-1:0]  resize_data_out ,   //图像数据
// 场同步开始与场同步结束标志
    output  wire            cmos_vsync_begin,   //场同步开始
    output  wire            cmos_vsync_end     //场同步结束
);


//----------------------------------------------------------------------
//rgb2gray
//----------------------------------------------------------------------

wire            dvp_pclk_out    ;   //有效图像使能信号
wire            dvp_href_out ;   //有效图像数据
wire            dvp_vsync_out    ;   //有效图像使能信号
wire     [7:0]  dvp_data_out ;   //有效图像数据

rgb2gray rgb2gray_inst(
    .sys_rst_n          (sys_rst_n      ),  //复位信号

    .dvp_pclk_in        (dvp_pclk_in    ),  //摄像头像素时钟
    .dvp_href_in        (dvp_href_in    ),  //摄像头行同步信号
    .dvp_vsync_in       (dvp_vsync_in   ),  //摄像头场同步信号
    .dvp_data_in        (dvp_data_in    ),  //摄像头图像数据

    .dvp_pclk_out        (dvp_pclk_out    ),  //摄像头像素时钟
    .dvp_href_out        (dvp_href_out    ),  //摄像头行同步信号
    .dvp_vsync_out       (dvp_vsync_out   ),  //摄像头场同步信号
    .dvp_data_out        (dvp_data_out    )  //摄像头图像数据

);


//----------------------------------------------------------------------
//resize
//----------------------------------------------------------------------

localparam src_image_width  = 400;
localparam src_image_height = 320;
localparam dst_image_width  = 300;
localparam dst_image_height = 300;
localparam x_ratio          = 87381;    //  floor(src_image_width/dst_image_width*2^16)
localparam y_ratio          = 69905;    //  floor(src_image_height/dst_image_height*2^16)

//  Image data has been processed
wire                            post_img_vsync;
wire                            post_img_href;
wire            [7:0]           post_img_gray;

bilinear_interpolation
#(
    .C_SRC_IMG_WIDTH (src_image_width ),
    .C_SRC_IMG_HEIGHT(src_image_height),
    .C_DST_IMG_WIDTH (dst_image_width ),
    .C_DST_IMG_HEIGHT(dst_image_height),
    .C_X_RATIO       (x_ratio         ),        //  floor(C_SRC_IMG_WIDTH/C_DST_IMG_WIDTH*2^16)
    .C_Y_RATIO       (y_ratio         )         //  floor(C_SRC_IMG_HEIGHT/C_DST_IMG_HEIGHT*2^16)
)
u_bilinear_interpolation
(
    .clk_in1        (dvp_pclk_out        ),
    .clk_in2        (dvp_pclk_out        ),
    .rst_n          (sys_rst_n          ),
    
    //  Image data prepared to be processed
    .per_img_vsync1 (dvp_vsync_out  ),          //  Prepared Image data vsync valid signal
    .per_img_href   (dvp_href_out   ),          //  Prepared Image data href vaild  signal
    .per_img_gray   (dvp_data_out   ),          //  Prepared Image brightness input
    
    //  Image data has been processed
    .post_img_vsync1 (post_img_vsync ),          //  processed Image data vsync valid signal
    .post_img_href   (post_img_href  ),          //  processed Image data href vaild  signal
    .post_img_gray   (post_img_gray  )           //  processed Image brightness output
);


//----------------------------------------------------------------------
//dvp_gray
//----------------------------------------------------------------------

dvp_gray #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH)
)
dvp_gray_inst(
    .sys_rst_n       (sys_rst_n      ),  //复位信号
    .dvp_pclk        (dvp_pclk_out     ),  //摄像头像素时钟
    .dvp_href        (post_img_href    ),  //摄像头行同步信号
    .dvp_vsync       (post_img_vsync   ),  //摄像头场同步信号
    .dvp_data        (post_img_gray    ),  //摄像头图像数据

    .rgb888_wr_en       (resize_wr_en   ),  //图像数据有效使能信号
    .rgb888_data_out    (resize_data_out),   //图像数据

    .cmos_vsync_begin   (cmos_vsync_begin   ),    //场同步开始
    .cmos_vsync_end     (cmos_vsync_end   )    //场同步结束
);



assign resize_pclk=dvp_pclk_out;

endmodule

