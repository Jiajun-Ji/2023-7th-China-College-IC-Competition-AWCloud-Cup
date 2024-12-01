module dvp_ddr3_vga_top
#(
//参数
	//write参数
	parameter DVP_USER_DATA_WIDTH = 128,	//输入位宽128
	parameter DVP_AVALON_DATA_WIDTH = 128,	//输出位宽128
	parameter DVP_MEMORY_BASED_FIFO = 1,	//使用内部memory	
	parameter DVP_FIFO_DEPTH = 256,			//FIFO深度为256=8192/32
	parameter DVP_FIFO_DEPTH_LOG2 = 8,		//FIFO深度的位宽
	parameter DVP_ADDRESS_WIDTH = 32,		//地址线宽度
	parameter DVP_BURST_CAPABLE = 1,		//使能突发
	parameter DVP_MAXIMUM_BURST_COUNT = 16, //最大突发长度16
	parameter DVP_BURST_COUNT_WIDTH = 5,	//突发长度位宽
	//read参数
	parameter VGA_USER_DATA_WIDTH = 128,	//输入位宽128
	parameter VGA_AVALON_DATA_WIDTH = 128,	//输出位宽128
	parameter VGA_MEMORY_BASED_FIFO = 1,	//使用内部memory	
	parameter VGA_FIFO_DEPTH = 256,			//FIFO深度为256=8192/32
	parameter VGA_FIFO_DEPTH_LOG2 = 8,		//FIFO深度的位宽
	parameter VGA_ADDRESS_WIDTH = 32,		//地址线宽度
	parameter VGA_BURST_CAPABLE = 1,		//使能突发
	parameter VGA_MAXIMUM_BURST_COUNT = 1,  //最大突发长度16
	parameter VGA_BURST_COUNT_WIDTH = 1,	//突发长度位宽
	//读地址参数
	parameter LENGTH =  32'h0005DC00,			//一帧长度
	parameter BUFFER0 = 32'h30880000,			//写地址默认为BUFFER0启动
	parameter RESIZE_LENGTH =  32'h0015f90,			//一帧长度
	parameter BUFFER1 = BUFFER0+LENGTH,			//读地址默认为BUFFER1启动
	parameter BUFFER2 = BUFFER1+LENGTH			//为hps传输图片的地址
)
(
	input 					clk,			 //50M时钟
	input 					reset_n,         //硬件低电平输入复位
	
//dvp
	//dvp时序输入接口
    input   wire            dvp_pclk     ,   //摄像头像素时钟
    input   wire            dvp_href     ,   //摄像头行同步信号
    input   wire            dvp_vsync    ,   //摄像头场同步信号
    input   wire    [ 7:0]  dvp_data     ,   //摄像头图像数据
	//dvp_slave接口
	input 					dvp_chipselect,
	input [1:0]				dvp_as_address,
	input 					dvp_as_write,
	input [31:0]			dvp_as_writedata,
	input 					dvp_as_read,
	output wire [31:0]		dvp_as_readdata,
	//dvp_master接口
	output wire	[DVP_ADDRESS_WIDTH-1:0]			dvp_master_address,
	output wire									dvp_master_write,				
	output wire	[(DVP_AVALON_DATA_WIDTH/8)-1:0]	dvp_master_byteenable,
	output wire	[DVP_AVALON_DATA_WIDTH-1:0]		dvp_master_writedata,			
	output wire	[DVP_BURST_COUNT_WIDTH-1:0]		dvp_master_burstcount,			
	input										dvp_master_waitrequest,
	
	output wire	[DVP_ADDRESS_WIDTH-1:0]			dvp_master_address1,
	output wire									dvp_master_write1,				
	output wire	[(DVP_AVALON_DATA_WIDTH/8)-1:0]	dvp_master_byteenable1,
	output wire	[DVP_AVALON_DATA_WIDTH-1:0]		dvp_master_writedata1,			
	output wire	[DVP_BURST_COUNT_WIDTH-1:0]		dvp_master_burstcount1,			
	input										dvp_master_waitrequest1,
	
	//dvp_wire测试接口
	output wire [7:0]		dvp_cnt_go	 ,	   //记录目前hps启动了多少次
	
//vga
	//vga时序输出接口
    output  wire           	vga_clk     ,   //输出vga时钟,频率5MHz
    output  wire            vga_de    	,   //有效数据选通信号DE
    output  wire            vga_hsync   ,   //输出行同步信号
    output  wire            vga_vsync   ,   //输出场同步信号
    output  wire    [23:0]  vga_rgb     ,   //输出24bit像素信息
	//vga_slave接口
	input 					vga_chipselect,
	input [1:0]				vga_as_address,
	input 					vga_as_write,
	input [31:0]			vga_as_writedata,
	input 					vga_as_read,
	output wire [31:0]		vga_as_readdata,
	//vga_master接口
	output wire	[VGA_ADDRESS_WIDTH-1:0]			vga_master_address,
	output wire									vga_master_read,				
	output wire	[(VGA_AVALON_DATA_WIDTH/8)-1:0]	vga_master_byteenable,
	input wire	[VGA_AVALON_DATA_WIDTH-1:0]		vga_master_readdata,			
	input										vga_master_readdatavalid,
	output wire	[VGA_BURST_COUNT_WIDTH-1:0]		vga_master_burstcount,			
	input										vga_master_waitrequest,
	//vga_wire测试接口
	output					 vga_flag
);

//=======================================================
//信号定义
//=======================================================
wire vga_done;
wire dvp_done;
reg pinpang_flag;

wire [31:0]dvp_address;
wire [31:0]vga_address;
wire dvp_go;
wire vga_go;
wire dvp_buffer_status;
wire vga_buffer_status;
//=======================================================
//例化
//=======================================================

//dvp_ddr3_top
	dvp_ddr3_top_me #(
		.USER_DATA_WIDTH     (DVP_USER_DATA_WIDTH),
		.AVALON_DATA_WIDTH   (DVP_AVALON_DATA_WIDTH),
		.MEMORY_BASED_FIFO   (DVP_MEMORY_BASED_FIFO),
		.FIFO_DEPTH          (DVP_FIFO_DEPTH),
		.FIFO_DEPTH_LOG2     (DVP_FIFO_DEPTH_LOG2),
		.ADDRESS_WIDTH       (DVP_ADDRESS_WIDTH),
		.BURST_CAPABLE       (DVP_BURST_CAPABLE),
		.MAXIMUM_BURST_COUNT (DVP_MAXIMUM_BURST_COUNT),
		.BURST_COUNT_WIDTH   (DVP_BURST_COUNT_WIDTH),
		.LENGTH   (LENGTH),
		.RESIZE_LENGTH   (RESIZE_LENGTH),
		.BUFFER0   (BUFFER0)
	) dvp_ddr3_top_0 (
		.clk                (clk),                                     //         clock.clk
		.reset_n            (reset_n),            //         reset.reset_n
		
		.dvp_pclk           (dvp_pclk),                        //           dvp.dvp_pclk
		.dvp_href           (dvp_href),                        //              .dvp_href
		.dvp_vsync          (dvp_vsync),                       //              .dvp_vsync
		.dvp_data           (dvp_data),                         //              .dvp_data
		
		.as_address         (dvp_as_address),    //            as.address
		.as_write           (dvp_as_write),      //              .write
		.as_writedata       (dvp_as_writedata),  //              .writedata
		.as_read            (dvp_as_read),       //              .read
		.as_readdata        (dvp_as_readdata),   //              .readdata
		.chipselect         (dvp_chipselect), //              .chipselect
		
		.master_address     (dvp_master_address),           // avalon_master.address
		.master_burstcount  (dvp_master_burstcount),        //              .burstcount
		.master_byteenable  (dvp_master_byteenable),        //              .byteenable
		.master_waitrequest (dvp_master_waitrequest),       //              .waitrequest
		.master_write       (dvp_master_write),             //              .write
		.master_writedata   (dvp_master_writedata),         //              .writedata
		
		.master_address1     (dvp_master_address1),           // avalon_master.address
		.master_burstcount1  (dvp_master_burstcount1),        //              .burstcount
		.master_byteenable1  (dvp_master_byteenable1),        //              .byteenable
		.master_waitrequest1 (dvp_master_waitrequest1),       //              .waitrequest
		.master_write1       (dvp_master_write1),             //              .write
		.master_writedata1   (dvp_master_writedata1),         //              .writedata
		
		.dvp_address         (dvp_address),                     //          wire.cnt_go
		.dvp_done            (dvp_done),                     //          wire.cnt_go
		.dvp_go              (dvp_go),                     //          wire.cnt_go
		
		.cnt_go             (dvp_cnt_go),                     //          wire.cnt_go
		.buffer_status      (dvp_buffer_status)
	);

//ddr3_vga_top
	ddr3_vga_top_me #(
		.USER_DATA_WIDTH     (VGA_USER_DATA_WIDTH),
		.AVALON_DATA_WIDTH   (VGA_AVALON_DATA_WIDTH),
		.MEMORY_BASED_FIFO   (VGA_MEMORY_BASED_FIFO),
		.FIFO_DEPTH          (VGA_FIFO_DEPTH),
		.FIFO_DEPTH_LOG2     (VGA_FIFO_DEPTH_LOG2),
		.ADDRESS_WIDTH       (VGA_ADDRESS_WIDTH),
		.BURST_CAPABLE       (VGA_BURST_CAPABLE),
		.MAXIMUM_BURST_COUNT (VGA_MAXIMUM_BURST_COUNT),
		.BURST_COUNT_WIDTH   (VGA_BURST_COUNT_WIDTH),
		.LENGTH   (LENGTH),
		.BUFFER0   (BUFFER0)
	) ddr3_vga_top_0 (
		.clk                  (clk),                                     //         clock.clk
		.reset_n              (reset_n),            //         reset.reset_n
		
		.vga_vsync            (vga_vsync),                   //           vga.vga_vsync
		.vga_rgb              (vga_rgb),                     //              .vga_rgb
		.vga_hsync            (vga_hsync),                   //              .vga_hsync
		.vga_de               (vga_de),                      //              .vga_de
		.vga_clk              (vga_clk),                     //              .vga_clk
		
		.as_address           (vga_as_address),    //            as.address
		.as_write             (vga_as_write),      //              .write
		.as_writedata         (vga_as_writedata),  //              .writedata
		.as_read              (vga_as_read),       //              .read
		.as_readdata          (vga_as_readdata),   //              .readdata
		.chipselect           (vga_chipselect), //              .chipselect
		
		.master_address       (vga_master_address),           // avalon_master.address
		.master_read          (vga_master_read),              //              .read
		.master_byteenable    (vga_master_byteenable),        //              .byteenable
		.master_readdata      (vga_master_readdata),          //              .readdata
		.master_readdatavalid (vga_master_readdatavalid),     //              .readdatavalid
		.master_burstcount    (vga_master_burstcount),        //              .burstcount
		.master_waitrequest   (vga_master_waitrequest),       //              .waitrequest

		.vga_address          (vga_address),                     //          wire.cnt_go
		.vga_done             (vga_done),                     //          wire.cnt_go
		.vga_go               (vga_go),                     //          wire.cnt_go
		
		.flag                 (vga_flag),                                                //          wire.flag
		.buffer_status        (vga_buffer_status)
	);

//=======================================================
//逻辑
//=======================================================

//检测两个done信号上升沿
reg [1:0]D4;
wire dvp_done_posedge;
always @(posedge clk or negedge reset_n)begin
    if(reset_n == 1'b0)begin
        D4 <= 2'b00;
    end
    else begin
        D4 <= {D4[0], dvp_done};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  dvp_done_posedge = ~D4[1] & D4[0];

reg [1:0]D5;
wire vga_done_posedge;
always @(posedge clk or negedge reset_n)begin
    if(reset_n == 1'b0)begin
        D5 <= 2'b00;
    end
    else begin
        D5 <= {D5[0], vga_done};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  vga_done_posedge = ~D5[1] & D5[0];

//状态机操作
//状态定义
parameter IDLE = 4'b0001, //初始状态
          Wbuffer0 = 4'b0010, //写 RAM1 状态
          wbuffer1_rbuffer0 = 4'b0100, //写 RAM2 读 RAM1 状态
          Wbuffer0_rbuffer1 = 4'b1000; //写 RAM1 读 RAM2 状态
//信号定义
reg [3:0] state; //状态机状态
reg       once_flag; //第一次写信号，不进行读
//状态机状态跳转
always@(negedge clk or negedge reset_n)//使用下降沿进行状态跳转，防止对上升沿数据采样造成影响
    if(reset_n == 1'b0) begin
        state <= IDLE;
        once_flag <= 0;
    end
    else case(state)
        IDLE://只在初始进入一次，跳转到写buffer0状态
            if(once_flag == 1'b0) begin
                state <= Wbuffer0;
                once_flag <= 1;
            end
        Wbuffer0://第一次写完buffer0，跳转到写buffer1读buffer0状态
            if(dvp_done_posedge == 1)
                state <= wbuffer1_rbuffer0;
        wbuffer1_rbuffer0://写完buffer1读完buffer0，跳转到写buffer0读buffer1状态
            if(dvp_done_posedge)//该值为0代表写buffer0读buffer1,以写入为目标进行切换
                state <= Wbuffer0_rbuffer1;
        Wbuffer0_rbuffer1://RAM1 数据写完之后，跳转到写 RAM2 读 RAM1 状态
            if(dvp_done_posedge)
                state <= wbuffer1_rbuffer0;
        default:
        state <= IDLE;
    endcase
	
//根据状态进行地址赋值
reg [31:0]dvp_address1;
reg [31:0]vga_address1;
reg dvp_go1;
reg vga_go1;
reg dvp_buffer_status1;
reg vga_buffer_status1;
always@(*)
    case(state)
        IDLE:
            begin
				dvp_buffer_status1=0;//为0代表写入buffer1
				vga_buffer_status1=0;//为0代表写入buffer0
                dvp_address1 = 32'b0;
                vga_address1 = 32'b0;
				dvp_go1=0;
				vga_go1=0;
            end
        Wbuffer0:
            begin
				dvp_go1=1;//启动dvp捕获
                dvp_address1 = BUFFER0;
                vga_address1 = 0;
            end
        wbuffer1_rbuffer0:
            begin
				vga_go1=1;//启动vga捕获
                dvp_address1 = BUFFER1;
                vga_address1 = BUFFER0;
				dvp_buffer_status1=0;//为0代表写入buffer1
				vga_buffer_status1=0;//为0代表写入buffer0
            end
        Wbuffer0_rbuffer1:
            begin
                dvp_address1 = BUFFER0;
                vga_address1 = BUFFER1;
				dvp_buffer_status1=1;//为1代表写入buffer0
				vga_buffer_status1=1;//为1代表写入buffer1
            end
        default:;
    endcase

assign dvp_address=dvp_address1;//dvp默认使用BUFFER0
assign vga_address=vga_address1;//vga默认使用BUFFER1
assign dvp_go=dvp_go1;//dvp默认使用BUFFER0
assign vga_go=vga_go1;//vga默认使用BUFFER1

//给hps发送状态信息
assign dvp_buffer_status=dvp_buffer_status1;//为1代表写入buffer0，为0代表写入buffer1
assign vga_buffer_status=vga_buffer_status1;//为0代表写入buffer0，为1代表写入buffer1



endmodule