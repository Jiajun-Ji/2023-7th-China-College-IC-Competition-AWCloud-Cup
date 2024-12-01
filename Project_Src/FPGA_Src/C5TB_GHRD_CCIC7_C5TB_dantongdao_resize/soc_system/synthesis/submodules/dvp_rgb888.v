module  dvp_rgb888
#(
//参数
	parameter USER_DATA_WIDTH = 128		//输入位宽32
)
(
    input   wire            sys_rst_n       ,   //复位信号
// dvp时序
    input   wire            dvp_pclk     ,   //摄像头像素时钟
    input   wire            dvp_href     ,   //摄像头行同步信号
    input   wire            dvp_vsync    ,   //摄像头场同步信号
    input   wire    [ 7:0]  dvp_data     ,   //摄像头图像数据
// 写FIFO
    output  wire            rgb888_wr_en    ,   //图像数据有效使能信号
    output  wire    [USER_DATA_WIDTH-1:0]  rgb888_data_out ,   //图像数据
// 场同步开始与场同步结束标志
    output  wire            cmos_vsync_begin,   //场同步开始
    output  wire            cmos_vsync_end     //场同步结束
);
parameter register_cnt = (USER_DATA_WIDTH-8)/8;	//输入位宽寄存几次
parameter register_width = USER_DATA_WIDTH-8;	//输入位宽

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//reg定义
reg                            dvp_vsync_dly;  //摄像头输入场同步信号打拍
reg     [register_width-1:0]   pic_data_reg;   //输入24位图像数据缓存寄存
reg     [USER_DATA_WIDTH-1:0]  data_out_reg;   //输出32位图像数据缓存
wire                           data_flag;      //图像数据拼接标志信号
reg                            data_flag_dly1; //图像数据拼接标志信号打拍
reg                            data_flag_dly2; //图像数据拼接标志信号打拍
reg	    [4:0]                  cnt1;            //计数时钟上升沿次数
wire	                       div_three;       //三分频
//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//

//使用PLL
div_three_pll_0002 div_three_pll_inst (
	.refclk   (dvp_pclk),   //  refclk.clk
	.rst      (~sys_rst_n),      //   reset.reset高电平复位
	.outclk_0 (div_three), // outclk0.clk
);

//dvp_vsync_dly:摄像头输入场同步信号打拍,用于产生cmos_vsync_begin
always@(posedge dvp_pclk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        dvp_vsync_dly    <=  1'b0;
    else
        dvp_vsync_dly    <=  dvp_vsync;

//cmos_vsync_begin:帧图像标志信号,每拉高一次,代表场同步信号高电平开始
//cmos_vsync_end:帧图像标志信号,每拉高一次,代表场同步信号低电平开始
assign  cmos_vsync_begin = ((dvp_vsync_dly == 1'b0)&& (dvp_vsync == 1'b1)) ? 1'b1 : 1'b0;
assign  cmos_vsync_end = ((dvp_vsync_dly == 1'b1)&& (dvp_vsync == 1'b0)) ? 1'b1 : 1'b0;

//产生data_flag信号
always@(posedge div_three or negedge sys_rst_n)
	if(!sys_rst_n)
		cnt1 <= 5'b0;
	else if(cnt1==register_cnt)
		cnt1 <= 5'b0;
	else if(dvp_href == 1'b1)
		cnt1 <= cnt1+1'b1;
	else 
		cnt1 <= cnt1;
		
assign	data_flag=(dvp_href == 1'b1&&cnt1==register_cnt)?1'b1:1'b0;

//dvp_data放前面就是大端，否则小端
//data_out_reg,pic_data_reg,data_flag:输出24位图像数据缓冲
//输入8位图像数据缓存输入8位,图像数据缓存
always@(posedge div_three or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            pic_data_reg    <=  0;
            data_out_reg    <=  0;
        end
    else    if(dvp_href == 1'b1)
        begin
            pic_data_reg    <=  {dvp_data,pic_data_reg[register_width-1:8]};
            if(data_flag == 1'b1)
                data_out_reg    <=  {dvp_data,pic_data_reg};
            else
                data_out_reg    <=  data_out_reg;
        end
    else
        begin
            pic_data_reg    <=  0;
            data_out_reg    <=  data_out_reg;
        end		
		
//data_flag_dly1:三分频图像数据缓存打拍
always@(posedge div_three or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data_flag_dly1  <=  1'b0;
    else
        data_flag_dly1  <=  data_flag;		
//data_flag_dly2:dvp_pclk图像数据缓存打拍
always@(posedge dvp_pclk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data_flag_dly2  <=  1'b0;
    else
        data_flag_dly2  <=  data_flag;	


//rgb888_wr_en:输出24位图像数据使能
assign  rgb888_wr_en = data_flag_dly1&data_flag_dly2;

//rgb888_data_out:输出24位图像数据
assign  rgb888_data_out = data_out_reg;
		
endmodule
