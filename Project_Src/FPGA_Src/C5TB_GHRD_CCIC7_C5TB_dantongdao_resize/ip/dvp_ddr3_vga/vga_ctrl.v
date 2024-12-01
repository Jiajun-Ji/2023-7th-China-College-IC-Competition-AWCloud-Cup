module  vga_ctrl
#(
//参数
	parameter USER_DATA_WIDTH = 128		//输入位宽
)
(
    input   wire            clk    		,   //输入工作时钟,频率5MHz
    input   wire            sys_rst_n   ,   //输入复位信号,低电平有效
	//vga时序输出
    output  wire           	vga_clk     ,   //输出vga时钟,频率5MHz
    output   wire           vga_de    	,   //有效数据选通信号DE
    output  wire            vga_hsync   ,   //输出行同步信号
    output  wire            vga_vsync   ,   //输出场同步信号
    output  wire    [23:0]  vga_rgb     ,   //输出24bit像素信息
	//读数据
	output  wire            read_req	,   			//数据请求信号
	input   wire    [USER_DATA_WIDTH-1:0]  read_data,   	//读数据
	// 场同步开始与场同步结束标志
    output  wire            cmos_vsync_begin,   //场同步开始
    output  wire            cmos_vsync_end     //场同步结束
);

//=======================================================
//参数定义
//=======================================================

parameter H_SYNC    =    10'd40  ,   //行同步
          H_BACK    =    10'd0   ,   //行时序后沿
          H_VALID   =    10'd400 ,   //行有效数据
          H_FRONT   =    10'd0   ,   //行时序前沿
          H_TOTAL   =    10'd440 ;   //行扫描周期
parameter V_SYNC    =  10'd40   ,   //场同步
          V_BACK    =  10'd20  ,   //场时序后沿
          V_VALID   =  10'd320 ,   //场有效数据
          V_FRONT   =  10'd0   ,   //场时序前沿
          V_TOTAL   =  10'd380 ;   //场扫描周期

//=======================================================
//信号定义
//=======================================================

//同步信号产生
reg     [9:0]   cnt_h           ;   //行同步信号计数器
reg     [9:0]   cnt_v           ;   //场同步信号计数器

//数据产生
reg    [USER_DATA_WIDTH-1:0]  data_reg1;   	//暂存3个read_data
reg    [USER_DATA_WIDTH-1:0]  data_reg;   	//移位输出vga_rgb
reg    [7:0]  					data;   		//寄存vga_rgb
reg	   [7:0]                 	cnt;            //计数时钟上升沿次数
reg            				    read_req1;	   //数据请求信号打一拍
reg            				    read_req2;	   //数据请求信号打一拍
wire            				pix_data_req;	   //数据请求信号打一拍
wire            				pix_data_req1;	   //数据请求信号打一拍

reg                             vga_vsync_dly;  //vga输出场同步信号打拍
//边沿检测
reg [1:0]D;				//边沿检测寄存器
wire neg_edge;			//捕捉read_req1信号下降沿

//=======================================================
//vga同步信号产生
//=======================================================

//vga_vsync_dly:vga输出场同步信号打拍,用于产生cmos_vsync_begin
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        vga_vsync_dly    <=  1'b0;
    else
        vga_vsync_dly    <=  vga_vsync;
//cmos_vsync_begin:帧图像标志信号,每拉高一次,代表场同步信号高电平开始
//cmos_vsync_end:帧图像标志信号,每拉高一次,代表场同步信号低电平开始
assign  cmos_vsync_begin = ((vga_vsync_dly == 1'b1)&& (vga_vsync == 1'b0)) ? 1'b1 : 1'b0;
assign  cmos_vsync_end = ((vga_vsync_dly == 1'b0)&& (vga_vsync == 1'b1)) ? 1'b1 : 1'b0;


//cnt_h:行同步信号计数器
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_h   <=  10'd0   ;
    else    if(cnt_h == H_TOTAL - 1'd1)
        cnt_h   <=  10'd0   ;
    else
        cnt_h   <=  cnt_h + 1'd1   ;

//vga_hsync:行同步信号
assign  vga_hsync = (cnt_h  <=  H_SYNC - 1'd1) ? 1'b0 : 1'b1  ;

//cnt_v:场同步信号计数器
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_v   <=  10'd0 ;
    else    if((cnt_v == V_TOTAL - 1'd1) &&  (cnt_h == H_TOTAL-1'd1))
        cnt_v   <=  10'd0 ;
    else    if(cnt_h == H_TOTAL - 1'd1)
        cnt_v   <=  cnt_v + 1'd1 ;
    else
        cnt_v   <=  cnt_v ;

//vga_vsync:场同步信号,高电平代表有效
assign  vga_vsync = (cnt_v  <=  V_SYNC - 1'd1) ? 1'b0 : 1'b1  ;

//vga_de:VGA有效显示区域
assign  vga_de = (((cnt_h >= H_SYNC + H_BACK )
                    && (cnt_h < H_SYNC + H_BACK + H_VALID))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK  + V_VALID)))
                    ? 1'b1 : 1'b0;

//pix_data_req:像素点色彩信息请求信号,超前vga_de信号六个时钟周期
assign  pix_data_req = (((cnt_h >= H_SYNC + H_BACK - 4)
                    && (cnt_h < H_SYNC + H_BACK + H_VALID - 4))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK + V_VALID)))
                    ? 1'b1 : 1'b0;

//pix_data_req1:像素点色彩信息请求信号,超前vga_de信号2个时钟周期,尾部加长一周期
assign  pix_data_req1 = (((cnt_h >= H_SYNC + H_BACK - 2)
                    && (cnt_h < H_SYNC + H_BACK + H_VALID - 1))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK + V_VALID)))
                    ? 1'b1 : 1'b0;					
					
					
//delete_area:丢弃六个128的区域
wire            				delete_area;	   //丢弃六个128的区域
assign  delete_area = (((cnt_h >= H_SYNC + H_BACK + H_VALID-80)//16*6
                    && (cnt_h < H_SYNC + H_BACK + H_VALID))
                    &&((cnt_v >= V_SYNC + V_BACK-1 )
                    && (cnt_v <V_SYNC + V_BACK)))
                    ? 1'b1 : 1'b0;				
//=======================================================
//数据产生
//=======================================================

//产生写请求read_req信号
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		cnt <= 8'b0;
	else if(cnt==15)//为15时将cnt清零一次
		cnt <= 8'b0;
	else if(pix_data_req == 1'b1||delete_area== 1'b1)
		cnt <= cnt+1'b1;
	else 
		cnt <= cnt;
// assign	read_req=(pix_data_req == 1'b1&&(cnt<=5'd2))?1'b1:1'b0;
assign	read_req=((pix_data_req == 1'b1||delete_area== 1'b1)&&(cnt<8'd1))?1'b1:1'b0;

//写请求read_req信号打一拍
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		read_req1 <= 1'b0;
	else 
		read_req1 <= read_req;

//写请求read_req1信号打一拍
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		read_req2 <= 1'b0;
	else 
		read_req2 <= read_req1;

//data_reg1信号寄存
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            data_reg1    <=  0;
        end
    else    if(pix_data_req == 1'b1)//在超前有效范围内
        begin
            if(read_req1 == 1'b1)//写请求打一拍信号有效
				data_reg1    <=  {read_data};
            else
                data_reg1    <=  data_reg1;
        end
    else
        begin
            data_reg1    <=  0;
            data_reg    <=  data_reg;
        end		
		
//data_reg赋值
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n) begin
		data_reg <= 0;
		data <= 0;
    end
	else if(read_req2==1) begin
		data <= data_reg[7:0];//在赋值data_reg时将其寄存器内部清空
		data_reg <= data_reg1;
    end
	else if(pix_data_req1==1) begin
			data <= data_reg[7:0];
			data_reg <= {8'b0,data_reg[USER_DATA_WIDTH-1:8]};//放前面就从后面出
		end
	else begin
		data <= 0;
		data_reg <= data_reg;
	end
		
//vga_rgb:输出像素点色彩信息
// assign  vga_rgb = (vga_de == 1'b1) ? {vga_B,vga_G,vga_R} : 24'b0 ;//测试
// assign  vga_rgb = (vga_de == 1'b1) ? {data[7:0],data[7:0],data[7:0]} : 24'b0 ;//反向尝试
assign  vga_rgb = (vga_de == 1'b1) ? {data,data,data} : 24'b0 ;
assign  vga_clk = clk;

// //vga时序测试
wire [31:0]x;
wire [31:0]y;
assign x=(cnt_h>H_SYNC+H_BACK-1'b1)&&(cnt_h<H_SYNC+H_BACK+H_VALID)?(cnt_h-H_SYNC-H_BACK+1'b1):32'd0;//(1~800) screen x coordinate
assign y=(cnt_v>V_SYNC+V_BACK-1'b1)&&(cnt_v<V_SYNC+V_BACK+V_VALID)?(cnt_v-V_SYNC-V_BACK+1'b1):32'd0;//(1~600) screen y coordinate

//输入图像像素
reg [7:0]vga_R;
reg [7:0]vga_G;
reg [7:0]vga_B;
	always@(posedge clk or negedge sys_rst_n)begin
		if(!sys_rst_n)begin
		vga_R<=0;
		vga_G<=0;
		vga_B<=0;
		end
		else begin
			if(x==0)begin
				vga_R<=0;
				vga_G<=0;
				vga_B<=0;
			end
			else if(x<H_VALID/3)begin//黄色
				vga_R<=8'd255;
				vga_G<=8'd255;
				vga_B<=8'd0;
			end
			else if(x<H_VALID*2/3)begin//蓝色
				vga_R<=8'd0;
				vga_G<=8'd255;
				vga_B<=8'd255;
			end
			else begin//绿色
				vga_R<=8'd0;
				vga_G<=8'd255;
				vga_B<=8'd0;
			end
		end
	end


endmodule
