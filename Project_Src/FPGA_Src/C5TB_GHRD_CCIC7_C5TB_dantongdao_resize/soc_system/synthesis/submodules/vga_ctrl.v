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
    output  wire            cmos_vsync_end,     //场同步结束
	//输入绘框信号
	//框数标志
    input   wire   [9:0]   num_rec  ,     //框数
	//框坐标
    input   wire   [9:0]   zuoshang_x  ,   //左上框x
    input   wire   [9:0]   zuoshang_y  ,   //左上框y
    input   wire   [9:0]   youxia_x    ,   //右下框x
    input   wire   [9:0]   youxia_y    ,   //右下框y
	//框标签
	input    wire  [2:0]   label		,
	//总体传输标志位
	input    wire 			all_rec     ,
	//单个框传输标志位
	input    wire 			single_rec	,
	//框置信度
	input    wire  [13:0]  acc			
);

//=======================================================
//参数定义5M时钟35帧
//=======================================================

parameter H_SYNC    =    10'd15  ,   //行同步    
          H_BACK    =    10'd0   ,   //行时序后沿
          H_VALID   =    10'd400 ,   //行有效数据
          H_FRONT   =    10'd0   ,   //行时序前沿
          H_TOTAL   =    10'd415 ;   //行扫描周期
parameter V_SYNC    =  10'd14   ,   //场同步     
          V_BACK    =  10'd10  ,   //场时序后沿  
          V_VALID   =  10'd320 ,   //场有效数据  
          V_FRONT   =  10'd0   ,   //场时序前沿  
          V_TOTAL   =  10'd344 ;   //场扫描周期   

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
wire vga_de1;   //有效信号开始
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

//vga_de1:VGA有效显示区域
assign  vga_de1 = (((cnt_h >= H_SYNC + H_BACK )
                    && (cnt_h < H_SYNC + H_BACK + H_VALID))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK  + V_VALID)))
                    ? 1'b1 : 1'b0;

//pre_vga_de:超前vga_de信号1个时钟周期
assign  pre_vga_de = (((cnt_h >= H_SYNC + H_BACK-1 )
                    && (cnt_h < H_SYNC + H_BACK + H_VALID-1))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK  + V_VALID)))
                    ? 1'b1 : 1'b0;

//pix_data_req:像素点色彩信息请求信号,超前vga_de信号4个时钟周期
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
wire            				delete_area;	   //丢弃五个128的区域
assign  delete_area = (((cnt_h >= H_SYNC + H_BACK + H_VALID-80)//16*5
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

//=======================================================
//vga有效显示区域像素点坐标
//=======================================================
wire    [9:0]   pix_x;   //输出VGA有效显示区域像素点X轴坐标
wire    [9:0]   pix_y;   //输出VGA有效显示区域像素点Y轴坐标
reg     [9:0]   pix_x_cnt;   //输出VGA有效显示区域像素点X轴坐标
reg     [9:0]   pix_y_cnt;   //输出VGA有效显示区域像素点Y轴坐标
wire            vga_de_begin;   //有效信号开始

//检测vga_de的上升沿
//vga_vsync_dly:vga输出场同步信号打拍,用于产生cmos_vsync_begin
reg        vga_de_dly;  //vga_de打拍
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        vga_de_dly    <=  1'b0;
    else
        vga_de_dly    <=  vga_de1;
assign  vga_de_begin = ((vga_de_dly == 1'b1)&& (vga_de1 == 1'b0)) ? 1'b1 : 1'b0;


//pix_x_cnt:X轴坐标计数器,超前真正的像素点一个时钟周期，使得我们可以根据该坐标对像素值进行赋值
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        pix_x_cnt   <=  10'd0   ;
    else    if(pre_vga_de == 1'd1)
        pix_x_cnt   <=  pix_x_cnt + 1'd1   ;
    else
        pix_x_cnt   <=  10'd0   ;

//pix_y_cnt:Y轴坐标计数器
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        pix_y_cnt   <=  10'd0   ;
    else    if(vga_de_begin == 1'd1)
        pix_y_cnt   <=  pix_y_cnt + 1'd1   ;
    else    if(pix_y_cnt == V_VALID)
        pix_y_cnt   <=  10'd0   ;
    else
        pix_y_cnt   <= pix_y_cnt;

assign pix_x=pix_x_cnt;
assign pix_y=pix_y_cnt;

//=======================================================
//字符显示数据
//=======================================================
reg     [255:0] char [63:0];    //字符数据
reg     [63:0] ca_shang [15:0];    //字符数据
reg     [71:0] zhen_kong [15:0];   //字符数据
reg     [63:0] zhe_zhou [15:0];    //字符数据
reg     [55:0] zang_wu [15:0];    //字符数据


reg     [7:0] xiaoshudian [15:0];  //字符数据
reg     [7:0] zero [15:0];  //字符数据
reg     [7:0] one  [15:0];  //字符数据
reg     [7:0] two  [15:0];  //字符数据
reg     [7:0] three [15:0];  //字符数据
reg     [7:0] four  [15:0];  //字符数据
reg     [7:0] five  [15:0];  //字符数据
reg     [7:0] six [15:0];  //字符数据
reg     [7:0] seven  [15:0];  //字符数据
reg     [7:0] eight  [15:0];  //字符数据
reg     [7:0] nine  [15:0];  //字符数据

//=======================================================
//字符显示像素点坐标
//=======================================================
parameter   CHAR_B_H=   10'd20 ,   //字符开始X轴坐标
            CHAR_B_V=   10'd10 ;   //字符开始Y轴坐标
parameter   CHAR_W  =   10'd72 ,   //字符宽度
            CHAR_H  =   10'd16  ;   //字符高度
wire    [9:0]   char_x  ;   //字符显示X轴坐标
wire    [9:0]   char_y  ;   //字符显示Y轴坐标
wire     flag;   //是否输出字符像素的flag

//=======================================================
//字符显示数据赋值
//=======================================================

parameter   BLACK   =   8'h00,   //黑色
            WHITE   =   8'hFF;   //白色
reg     [7:0] data1;   //字符数据

//输出8位数据赋值
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data1<= data;
    else    if( flag== 1'b1)//字符结束y
        data1    <=  WHITE;//当处于字符显示区域且在该区域内像素为1时进行显示
    else
        data1    <=  data;

//=======================================================
//数据输出
//=======================================================
wire [23:0] vga_rgb1;
//vga_rgb:输出像素点色彩信息
assign  vga_de=vga_de_dly;
// assign  vga_rgb = (vga_de1 == 1'b1) ? {data,data,data} : 24'b0 ;
assign  vga_rgb = (vga_de == 1'b1) ? {data1,data1,data1} : 24'b0 ;
assign  vga_clk = clk;

//=======================================================
//测试
//=======================================================
reg    [9:0]   text_x;   //测试起始点x坐标
reg    [9:0]   text_y;   //测试起始点y坐标
//产生一个随帧数变化的坐标
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            text_x   <=  0 ;
            text_y   <=  0 ;
        end
    else    if(cmos_vsync_begin == 1'd1)//一帧变化一次
        begin
            text_x   <=  text_x + 1'd1   ;
            text_y   <=  text_y + 1'd1   ;
        end
    else    if(text_x == H_VALID-1)
        text_x   <=  10'd0   ;
    else    if(text_y == V_VALID-1)
        text_y   <=  10'd0   ;
    else
        begin
            text_x   <=  text_x ;
            text_y   <=  text_y ;
        end
		
//=======================================================
//接收传入的框
//=======================================================
parameter number=4;
reg   [9:0] zuoshang_x_rec [number:0] ;
reg   [9:0] zuoshang_y_rec [number:0] ;
reg   [9:0] youxia_x_rec [number:0] ;
reg   [9:0] youxia_y_rec [number:0] ;
reg   [13:0] acc_rec [number:0] ;
reg   [2:0] label_rec [number:0] ;
reg   [3:0] rec_cnt;


//检测single_rec的上升/下降沿
reg        single_rec_dly;  
wire       single_rec_begin;   
wire       single_rec_end;   
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        single_rec_dly    <=  1'b0;
    else
        single_rec_dly    <=  single_rec;
assign  single_rec_begin = ((single_rec_dly == 1'b0)&& (single_rec == 1'b1)) ? 1'b1 : 1'b0;
assign  single_rec_end = ((single_rec_dly == 1'b1)&& (single_rec == 1'b0)) ? 1'b1 : 1'b0;

//检测all_rec的上升/下降沿
reg        all_rec_dly;  
wire       all_rec_begin;   
wire       all_rec_end;   
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        all_rec_dly    <=  1'b0;
    else
        all_rec_dly    <=  all_rec;
assign  all_rec_begin = ((all_rec_dly == 1'b0)&& (all_rec == 1'b1)) ? 1'b1 : 1'b0;
assign  all_rec_end = ((all_rec_dly == 1'b1)&& (all_rec == 1'b0)) ? 1'b1 : 1'b0;


//对传入的框数进行计数
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0 )
            rec_cnt   <=  0;
    else    if(all_rec == 1'd1 && single_rec_begin == 1'd1)//在总体传输过程中，开始一次传输
            rec_cnt   <=  rec_cnt + 1'd1   ;
    else    if(all_rec_begin == 1'd1)	//每次开始总体传输复位一次
            rec_cnt   <=  0;		
    else
            rec_cnt   <=  rec_cnt    ;

//赋值
integer i;
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0 ) begin
        for(i=0; i<=number; i=i+1)
            begin
                zuoshang_x_rec[i][9:0] <= 0;
                zuoshang_y_rec[i][9:0] <= 0;
                youxia_x_rec[i][9:0]   <= 0;
                youxia_y_rec[i][9:0]   <= 0;
                acc_rec[i][13:0]       <= 0;
                label_rec[i][2:0]      <= 0;
            end
    end 
    else    if(all_rec == 1'd1 && single_rec_end == 1'd1)//在总体传输过程中，结束一次传输
        begin
            zuoshang_x_rec[rec_cnt][9:0] <= zuoshang_x;
            zuoshang_y_rec[rec_cnt][9:0] <= zuoshang_y;
            youxia_x_rec[rec_cnt][9:0]   <= youxia_x;
            youxia_y_rec[rec_cnt][9:0]   <= youxia_y;
            acc_rec[rec_cnt][13:0]       <= acc;
            label_rec[rec_cnt][2:0]      <= label;
        end 
    else begin
            zuoshang_x_rec[rec_cnt][9:0] <= zuoshang_x_rec[rec_cnt][9:0];
            zuoshang_y_rec[rec_cnt][9:0] <= zuoshang_y_rec[rec_cnt][9:0];
            youxia_x_rec[rec_cnt][9:0]   <= youxia_x_rec[rec_cnt][9:0];
            youxia_y_rec[rec_cnt][9:0]   <= youxia_y_rec[rec_cnt][9:0];
            acc_rec[rec_cnt][13:0]       <= acc_rec[rec_cnt][13:0];
            label_rec[rec_cnt][2:0]      <= label_rec[rec_cnt][2:0];
    end



//=======================================================
//多框显示，利用框数，最大显示4个框
//=======================================================

wire     flag1;   //第1个单元框
wire     flag2;   //第2个单元框
wire     flag3;   //第3个单元框
wire     flag4;   //第4个单元框
wire     rec1;   //第1个单元框
wire     rec2;   //第2个单元框
wire     rec3;   //第3个单元框
wire     rec4;   //第4个单元框

//第一个矩形框显示单元
flag_generate flag_generate_inst1(
    .clk             (clk     ),      //时钟信号
    .sys_rst_n       (sys_rst_n   ),  //复位信号

    .pix_x           (pix_x     ),     //传入VGA有效显示坐标
    .pix_y           (pix_y    ),      //传入VGA有效显示坐标

    .zuoshang_x       (zuoshang_x_rec[1][9:0] ),   //左上框x
    .zuoshang_y       (zuoshang_y_rec[1][9:0] ),   //左上框y
    .youxia_x         (youxia_x_rec[1][9:0]   ),   //右下框x
    .youxia_y         (youxia_y_rec[1][9:0]   ),   //右下框y

    .start       	  (all_rec_end ),   //启动bin2bcd
    .acc   			  (acc_rec[1][13:0]     ),   //置信度
	
    .label            (label_rec[1][2:0]    ),   //标签

    .flag             (flag1      )    //输出单个框单元的flag
);

//第二个矩形框显示单元
flag_generate flag_generate_inst2(
    .clk             (clk     ),      //时钟信号
    .sys_rst_n       (sys_rst_n   ),  //复位信号

    .pix_x           (pix_x     ),     //传入VGA有效显示坐标
    .pix_y           (pix_y    ),      //传入VGA有效显示坐标

    .zuoshang_x       (zuoshang_x_rec[2][9:0]),   //左上框x
    .zuoshang_y       (zuoshang_y_rec[2][9:0]),   //左上框y
    .youxia_x         (youxia_x_rec[2][9:0]  ),   //右下框x
    .youxia_y         (youxia_y_rec[2][9:0]  ),   //右下框y

    .start       	  (all_rec_end ),   //启动bin2bcd
    .acc   			  (acc_rec[2][13:0]        ),   //置信度
	
    .label            (label_rec[2][2:0]      ),   //标签

    .flag             (flag2      )    //输出单个框单元的flag
);

//第三个矩形框显示单元
flag_generate flag_generate_inst3(
    .clk             (clk     ),      //时钟信号
    .sys_rst_n       (sys_rst_n   ),  //复位信号

    .pix_x           (pix_x     ),     //传入VGA有效显示坐标
    .pix_y           (pix_y    ),      //传入VGA有效显示坐标

    .zuoshang_x       (zuoshang_x_rec[3][9:0] ),   //左上框x
    .zuoshang_y       (zuoshang_y_rec[3][9:0] ),   //左上框y
    .youxia_x         (youxia_x_rec[3][9:0]   ),   //右下框x
    .youxia_y         (youxia_y_rec[3][9:0]   ),   //右下框y


    .start       	  (all_rec_end ),   //启动bin2bcd
    .acc   			  (acc_rec[3][13:0]        ),   //置信度
	
    .label            (label_rec[3][2:0]      ),   //标签

    .flag             (flag3      )    //输出单个框单元的flag
);

//第四个矩形框显示单元
flag_generate flag_generate_inst4(
    .clk             (clk     ),      //时钟信号
    .sys_rst_n       (sys_rst_n   ),  //复位信号

    .pix_x           (pix_x     ),     //传入VGA有效显示坐标
    .pix_y           (pix_y    ),      //传入VGA有效显示坐标

    .zuoshang_x       (zuoshang_x_rec[4][9:0] ),   //左上框x
    .zuoshang_y       (zuoshang_y_rec[4][9:0] ),   //左上框y
    .youxia_x         (youxia_x_rec[4][9:0]   ),   //右下框x
    .youxia_y         (youxia_y_rec[4][9:0]   ),   //右下框y

    .start       	  (all_rec_end ),   //启动bin2bcd
    .acc   			  (acc_rec[4][13:0]        ),   //置信度
	
    .label            (label_rec[4][2:0]      ),   //标签

    .flag             (flag4      )    //输出单个框单元的flag
);


//=======================================================
//只显示一帧且必须显示一帧的控制单元
//=======================================================
reg done_flag;
reg display;
reg        display_dly;  
wire       display_begin;   
wire       display_end;  

always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        done_flag    <=  1'b0;
    else if (all_rec_end==1) //如果传输完成,则done_flag被置为1
        done_flag    <=  1; 
    else if (display_end==1) //如果显示信号完成，代表一次显示完毕，将done信号还原为0
        done_flag    <=  0; 
    else
        done_flag    <=  done_flag;

//是否展显示的flag

always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        display    <=  1'b0;
    else if (done_flag==1 && (cmos_vsync_end)) //如果传输完成,且遇到帧头，则可以进行显示
        display    <=  1; 
    else if (display==1  && (cmos_vsync_begin)) //如果显示有效,且遇到帧尾,则一次显示完成
        display    <=  0; 
    else
        display    <=  display;

//检测display的上升/下降沿
 
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        display_dly    <=  1'b0;
    else
        display_dly    <=  display;
assign  display_begin = ((display_dly == 1'b0)&& (display == 1'b1)) ? 1'b1 : 1'b0;
assign  display_end = ((display_dly == 1'b1)&& (display == 1'b0)) ? 1'b1 : 1'b0;


//=======================================================
//输出
//=======================================================

assign rec1 = flag1&&(1<=num_rec); //当传入框数大于等于1时，flag1有效
assign rec2 = flag2&&(2<=num_rec);
assign rec3 = flag3&&(3<=num_rec);
assign rec4 = flag4&&(4<=num_rec);

assign flag =  rec1 || rec2 || rec3 || rec4;//将框和字符一起显示


endmodule