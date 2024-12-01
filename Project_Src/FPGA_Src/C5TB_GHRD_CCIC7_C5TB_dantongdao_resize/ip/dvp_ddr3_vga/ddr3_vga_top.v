module ddr3_vga_top_me
#(
//参数
	parameter USER_DATA_WIDTH = 128,	//输入位宽128
	parameter AVALON_DATA_WIDTH = 128,	//输出位宽128
	parameter MEMORY_BASED_FIFO = 1,	//使用内部memory	
	parameter FIFO_DEPTH = 256,			//FIFO深度为256=8192/32
	parameter FIFO_DEPTH_LOG2 = 8,		//FIFO深度的位宽
	parameter ADDRESS_WIDTH = 32,		//地址线宽度
	parameter BURST_CAPABLE = 0,		//使能突发
	parameter MAXIMUM_BURST_COUNT = 16, //最大突发长度16
	parameter BURST_COUNT_WIDTH = 5,		//突发长度位宽+1
		//读地址参数
	parameter LENGTH =  32'h0005DC00,			//一帧长度
	parameter BUFFER0 = 32'h30880000			//写地址默认为BUFFER0启动
)
(
	input 					clk,			 //50M时钟
	input 					reset_n,         //硬件低电平输入复位
	//vga时序输出接口
    output  wire           	vga_clk     ,   //输出vga时钟,频率5MHz
    output  wire            vga_de    	,   //有效数据选通信号DE
    output  wire            vga_hsync   ,   //输出行同步信号
    output  wire            vga_vsync   ,   //输出场同步信号
    output  wire    [23:0]  vga_rgb     ,   //输出24bit像素信息
	//avalon_mm_slave接口
	input 					chipselect,
	input [1:0]				as_address,
	input 					as_write,
	input [31:0]			as_writedata,
	input 					as_read,
	output wire [31:0]		as_readdata,
	//avalon_mm_master接口
	output wire	[ADDRESS_WIDTH-1:0]			master_address,
	output wire								master_read,				
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable,
	input wire	[AVALON_DATA_WIDTH-1:0]		master_readdata,			
	input									master_readdatavalid,
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount,			
	input									master_waitrequest,
	output									flag,
	
	//地址输入
	input							[31:0]			vga_address,
	//启动输入
	input									vga_go,
	//done信号输出
	output									vga_done,
	//读写buffer的状态
	input									buffer_status	
	);
//=======================================================
//参数定义
//=======================================================
	parameter BUFFER1 = BUFFER0+LENGTH;			//读地址默认为BUFFER1启动
	parameter BUFFER2 = BUFFER1+LENGTH;			//为hps传输图片的地址
//=======================================================
//信号定义
//=======================================================
//vga时钟
	wire        			   clk_5M;             
//ddr3_read
	//软件复位
	wire        			   soft_reset;             
	//control接口
	wire    [31:0] 			   control_read_base;     
	wire    [31:0] 			   control_read_length;   
	wire        			   control_fixed_location; 
	wire        			   control_go;            
	wire        			   control_done;  	
	wire        			   control_early_done;  	
	//user接口
	wire        			   user_read_clk;         
	wire        			   user_read_buffer;      
	wire        			   user_data_available;       
	wire [USER_DATA_WIDTH-1:0] user_buffer_data;       
	
//ddr3_vga_ctrl
	wire 			hps_start_cap;  	//hps发出的启动信号
	wire 	[1:0]	master_ctrl_en;    //控制寄存器（空余）
	wire 			status;            //状态寄存器，为1表示传输完成，为0代表正在传输

//vga_ctrl
	wire            cmos_vsync_begin;  //有效图像使能信号
	wire            cmos_vsync_end;    //有效图像数据
	wire            read_req;     	   //数据请求信号
	wire [USER_DATA_WIDTH-1:0]  read_data; //读数据

//其余信号
	//写帧数定义
	parameter MAXFRAME= 8'd1;//启动一次写1帧
	//帧捕获标志
	reg start_cap;			//开始捕捉帧信号，由hps发起，高电平有效，捕获完MAXFRAME帧后置位0
	reg en_cap;				//结束捕捉帧信号，start_cap有效时，场同步高电平结束时开始有效
	//控制信号
	reg control_go1;		//启动ddr3_write信号的寄存器
	reg hps_start_cap1;		//辅助捕捉信号
	reg [7:0]frame_count;	//帧计数器，用于控制读写多少帧，与MAXFRAME位宽相同
	//边沿检测
	reg [1:0]D;				//边沿检测寄存器
	reg [1:0]D1;
	wire pos_edge;			//hps启动捕捉帧上升沿，即hps_start_cap1上升沿
	wire done_pos_edge;		//传输完成信号上升沿，即control_done上升沿
	//传输状态信号
	reg status_register;	//status传输状态寄存器
	//测试接口
	reg [7:0]		cnt_go;			  //记录目前hps启动了多少次
	
	
//=======================================================
//例化
//=======================================================

//例化5M时钟
vga_pll_0002 vga_pll_inst (
	.refclk   (clk),   //  refclk.clk
	.rst      (~reset_n),      //   reset.reset高电平复位
	.outclk_0 (clk_5M) // outclk0.clk
);

//例化ddr3_read
ddr3_read #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH),
    .AVALON_DATA_WIDTH   (AVALON_DATA_WIDTH),
    .MEMORY_BASED_FIFO   (MEMORY_BASED_FIFO),
    .FIFO_DEPTH          (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2     (FIFO_DEPTH_LOG2),
    .ADDRESS_WIDTH       (ADDRESS_WIDTH),
    .BURST_CAPABLE       (BURST_CAPABLE),
    .MAXIMUM_BURST_COUNT (MAXIMUM_BURST_COUNT),
    .BURST_COUNT_WIDTH   (BURST_COUNT_WIDTH)
) ddr3_read_0 (
    .clk                    (clk),                                     
    .reset_n                (reset_n),      		 //低电平复位         
    .soft_reset             (soft_reset),   		 //高电平复位
	//control接口
    .control_read_base      (control_read_base),      //读地址
    .control_read_length    (control_read_length),    //读长度
    .control_fixed_location (),             
    .control_go             (control_go),            //开始写信号
    .control_done           (control_done),          //读完信号
    .control_early_done     (control_early_done),    //快读完信号
	//user接口
    .user_read_clk          (user_read_clk),    	 //读时钟    
    .user_read_buffer       (user_read_buffer), 	 //读请求      
    .user_buffer_data       (user_buffer_data),  	 //读数据   
    .user_data_available    (user_data_available),   //fifo是否空    
	//avalon_mm_master接口
    .master_address         (master_address),        
    .master_read            (master_read),          
    .master_byteenable      (master_byteenable),     
    .master_readdata        (master_readdata),      
    .master_readdatavalid   (master_readdatavalid),  //读数据有效信号
    .master_burstcount      (master_burstcount),     
    .master_waitrequest     (master_waitrequest)     
);

//ddr3_vga_ctrl
ddr3_vga_ctrl ddr3_vga_ctrl_0 (
	.clk                 (clk),                   
	.reset_n             (reset_n),       //低电平复位           
	//avalon_mm_slave接口
	.as_address          (as_address),         
	.as_write            (as_write),            
	.as_writedata        (as_writedata),        
	.as_read             (as_read),             
	.as_readdata         (as_readdata),       
	.chipselect          (chipselect),         
	//control接口
	.control_user_base   (control_read_base),    
	.control_user_length (control_read_length),  
	.control_go          (hps_start_cap),  			//hps写一帧脉冲
	.control_en          (master_ctrl_en),  		//预留控制寄存器
	.control_state       (buffer_status)            //传输状态
);

//vga_ctrl
vga_ctrl #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH)
)
vga_ctrl_inst(
    .clk             (clk_5M     ),  //时钟信号
    .sys_rst_n       (reset_n   ),  //复位信号
	//vga时序输出
    .vga_clk         (vga_clk     ),  //摄像头像素时钟
    .vga_de          (vga_de    ),  //摄像头行同步信号
    .vga_hsync       (vga_hsync   ),  //摄像头场同步信号
    .vga_vsync       (vga_vsync    ),  //摄像头图像数据
    .vga_rgb         (vga_rgb),         //图像数据
	//数据
    .read_req        (read_req   ),     //读请求
    .read_data       (read_data   ),    //读数据
	//场同步边沿
    .cmos_vsync_begin   (cmos_vsync_begin   ),    //场同步开始
    .cmos_vsync_end     (cmos_vsync_end   )    //场同步结束
);


//=======================================================
//控制逻辑
//=======================================================

//组合逻辑赋值
assign user_read_clk=vga_clk;//读时钟为vga时钟
assign user_read_buffer=read_req&en_cap;//读请求由读请求与捕捉有效信号共同作用
assign read_data=user_buffer_data;//读数据赋值
assign soft_reset=master_ctrl_en[0];//不使用软件复位（暂时不用）
assign vga_done=control_early_done;
//vga_clk下的时序

	//start_cap	
	always @(posedge vga_clk or negedge reset_n)
		if (reset_n == 1'b0)
			start_cap  <= 1'd0;
		else if(hps_start_cap1)
			start_cap <= 1'd1;
		else if(en_cap && cmos_vsync_begin) 
		begin
			start_cap  <= 1'd0;
		end
		else
			start_cap  <= start_cap;

	//en_cap
	always @(posedge vga_clk or negedge reset_n)
		if (reset_n == 1'b0)
			en_cap  <= 1'd0;
		else if (start_cap)begin
			if(cmos_vsync_end)
				en_cap  <= 1'd1;
			else if(cmos_vsync_begin)
				en_cap  <= 1'd0;
		end
		else
			en_cap  <= 1'd0;

	//产生control_go信号
	always @(posedge vga_clk or negedge reset_n)
		if (reset_n == 1'b0)
			control_go1  <= 1'd0;
		else if (start_cap)begin
			if(cmos_vsync_end)
				control_go1  <= 1'd1;
			else
				control_go1  <= 1'd0;
		end
		else
			control_go1  <= 1'd0;
	assign control_go=control_go1;//将reg赋值给wire

	//读取帧计数器
	always @(posedge vga_clk or negedge reset_n)
		if (reset_n == 1'b0) begin
			frame_count  <= 8'd0;
		end  
		else if(frame_count== MAXFRAME) begin//如果已经清空一次
			frame_count  <= 8'd0;
		end
		else if(control_go== 1'b1)
			frame_count <= frame_count + 1'b1;
		else
			frame_count  <= frame_count;
			
//clk_50下的时序

	//使用边沿检测检测启动信号上升沿，只会持续一个时钟周期(别用vga时钟检测)
	always @(posedge clk or negedge reset_n)begin
			if(reset_n == 1'b0)begin
				D <= 2'b00;
			end
			else begin
				D <= {D[0], hps_start_cap};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
			end
		end
	assign  pos_edge = ~D[1] & D[0];
		
	//使用边沿检测检测done信号上升沿，只会持续一个时钟周期(别用vga时钟检测)
	always @(posedge clk or negedge reset_n)begin
			if(reset_n == 1'b0)begin
				D1 <= 2'b00;
			end
			else begin
				D1 <= {D1[0], control_early_done};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
			end
		end
	assign  done_pos_edge = ~D1[1] & D1[0];
	
	//若达到一次标志信号的启动上限
	// always @(posedge clk)
		// if(hps_start_cap1==1'b0 && pos_edge==1'b1 ) begin
			// hps_start_cap1 <= 1'b1;
		// end
		// else if ((frame_count!=MAXFRAME)) begin
			// hps_start_cap1 <= hps_start_cap1;
		// end 
		// else begin
			// hps_start_cap1  <= 1'b0; 
		// end

	always @(posedge clk or negedge reset_n)//启动一次30帧传输
		if (reset_n == 1'b0) begin
			hps_start_cap1  <= 1'b0; 
		end  
		else if(hps_start_cap1==0 && pos_edge==1 ) begin
			hps_start_cap1 <= 1;
		end
		
	//真正的传输开始与结束状态status标志
	always @(posedge clk or negedge reset_n)
		if (reset_n == 1'b0)
			status_register  <= 1'd0;
		else if(pos_edge)//检测到启动信号上升沿就置为正在传输状态
			status_register  <= 1'd0;
		else if(done_pos_edge)//检测到done信号上升沿就置为传输完成状态
			status_register  <= 1'd1;
	assign  status = status_register;
	
//测试信号

	//计数启动次数用于测试
	always @(posedge pos_edge or negedge reset_n)
		if(reset_n == 1'b0)
			cnt_go <= 1'b0;
		else
			cnt_go <= cnt_go+1'b1;		
			
			
//新增测试用于singaltap抓取
			
//检测第一个de信号
reg [1:0]D2;
wire de_edge;
always @(posedge vga_clk or negedge reset_n)begin
    if(reset_n == 1'b0)begin
        D2 <= 2'b00;
    end
    else begin
        D2 <= {D2[0], vga_vsync};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  de_edge = ~D2[1] & D2[0];

reg  flag1;//记录第一个vga_de
always @(posedge vga_clk or negedge reset_n)
    if(reset_n == 1'b0)
        flag1 <= 1'b0;
    else if(de_edge==1)
        flag1 <= 1'b1;
    else if(vga_de==1)
        flag1 <= 1'b0;
    else
        flag1 <= flag1;
assign flag=flag1;


// //产生control_go信号
// reg [1:0]D3;
// wire GO_edge;
// always @(posedge vga_clk or negedge reset_n)begin
    // if(reset_n == 1'b0)begin
        // D3 <= 2'b00;
    // end
    // else begin
        // D3 <= {D3[0], flag1};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    // end
    // end
// assign  GO_edge = D3[1] & ~D3[0];

// always @(posedge vga_clk or negedge reset_n)
	// if (reset_n == 1'b0)
		// control_go1  <= 1'd0;
	// else if (GO_edge==1)begin
			// control_go1  <= 1'd1;
	// end
	// else
		// control_go1  <= 1'd0;
// assign control_go=control_go1;



endmodule