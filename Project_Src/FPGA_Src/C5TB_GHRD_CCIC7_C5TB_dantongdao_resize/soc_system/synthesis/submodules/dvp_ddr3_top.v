module dvp_ddr3_top_me
#(
//参数
	parameter USER_DATA_WIDTH = 128,	//输入位宽128
	parameter AVALON_DATA_WIDTH = 128,	//输出位宽128
	parameter MEMORY_BASED_FIFO = 1,	//使用内部memory	
	parameter FIFO_DEPTH = 256,			//FIFO深度为256=8192/32
	parameter FIFO_DEPTH_LOG2 = 8,		//FIFO深度的位宽
	parameter ADDRESS_WIDTH = 32,		//地址线宽度
	parameter BURST_CAPABLE = 1,		//使能突发
	parameter MAXIMUM_BURST_COUNT = 16, //最大突发长度16
	parameter BURST_COUNT_WIDTH = 5,		//突发长度位宽+1
			//读地址参数
	parameter LENGTH =  32'h0001f400,			//一帧长度
	parameter RESIZE_LENGTH =  32'h0015f90,			//一帧长度
	parameter BUFFER0 = 32'h30880000			//写地址默认为BUFFER0启动
)
(
	input 					clk,			 //50M时钟
	input 					reset_n,         //硬件低电平输入复位
	//dvp时序输入接口
    input   wire            dvp_pclk     ,   //摄像头像素时钟
    input   wire            dvp_href     ,   //摄像头行同步信号
    input   wire            dvp_vsync    ,   //摄像头场同步信号
    input   wire    [ 7:0]  dvp_data     ,   //摄像头图像数据
	//avalon_mm_slave接口
	input 					chipselect,
	input [1:0]				as_address,
	input 					as_write,
	input [31:0]			as_writedata,
	input 					as_read,
	output wire [31:0]		as_readdata,
	//avalon_mm_master接口
	output wire	[ADDRESS_WIDTH-1:0]			master_address,
	output wire								master_write,				
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable,
	output wire	[AVALON_DATA_WIDTH-1:0]		master_writedata,			
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount,			
	input									master_waitrequest,
	//avalon_mm_master接口
	output wire	[ADDRESS_WIDTH-1:0]			master_address1,
	output wire								master_write1,				
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable1,
	output wire	[AVALON_DATA_WIDTH-1:0]		master_writedata1,			
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount1,			
	input									master_waitrequest1,
	//测试接口
	output reg [7:0]		cnt_go,			  //记录目前hps启动了多少次
	
	//地址输入
	input					[31:0]	dvp_address,
	//启动输入
	input									dvp_go,
	//done信号输出
	output									dvp_done,
	//读写buffer的状态
	input									buffer_status
);
//=======================================================
//参数定义
//=======================================================
	parameter BUFFER1 = BUFFER0+LENGTH;			//读地址默认为BUFFER1启动
	parameter BUFFER2 = BUFFER1+LENGTH;			//为hps传输图片的地址
	parameter RESIZE_USER_DATA_WIDTH = 32;		//resize输出位宽32
	
//=======================================================
//信号定义
//=======================================================

//ddr3_write
	//软件复位
	wire        			   soft_reset;             
	//control接口
	wire    [31:0] 			   control_write_base;     
	wire    [31:0] 			   control_write_length;   
	wire        			   control_done;           
	wire        			   control_fixed_location; 
	wire        			   control_go;             
	//user接口
	wire        			   user_write_clk;         
	wire        			   user_write_buffer;      
	wire        			   user_buffer_full;       
	wire [USER_DATA_WIDTH-1:0] user_buffer_data;       

//dvp_ddr3_ctrl
	wire 			hps_control_go1;   //hps启动传输信号
	wire 	[1:0]	master_ctrl_en;    //控制寄存器（空余）
	wire 			status;            //状态寄存器，为1表示传输完成，为0代表正在传输

//dvp_rgb888
	wire            rgb888_wr_en;      //有效图像使能信号
	wire    [USER_DATA_WIDTH-1:0]  rgb888_data_out;   //有效图像数据，当前是128bit
	wire            cmos_vsync_begin;  //有效图像使能信号
	wire            cmos_vsync_end;    //有效图像数据
	
//resize_top
	wire            resize_pclk;
	wire            resize_wr_en;      //有效图像使能信号
	wire    [RESIZE_USER_DATA_WIDTH-1:0]  resize_data_out;   //有效图像数据，当前是32bit
	wire            resize_vsync_begin;  //有效图像使能信号
	wire            resize_vsync_end;    //有效图像数据



//其余信号
	//写帧数定义
	parameter MAXFRAME= 8'd1;//启动一次写1帧
	//帧捕获标志
	reg start_cap;			//开始捕捉帧信号，由hps发起，高电平有效，捕获完MAXFRAME帧后置位0
	reg en_cap;				//结束捕捉帧信号，start_cap有效时，场同步高电平结束时开始有效
	//控制信号
	reg control_go1;		//启动ddr3_write信号的寄存器
	reg hps_start_cap1;		//辅助捕捉信号
	wire hps_start_cap;  	//hps发出的启动信号
	reg [7:0]frame_count;	//帧计数器，用于控制读写多少帧，与MAXFRAME位宽相同
	//边沿检测
	reg [1:0]D;				//边沿检测寄存器
	reg [1:0]D1;
	wire pos_edge;			//hps启动捕捉帧上升沿，即hps_start_cap1上升沿
	wire done_pos_edge;		//传输完成信号上升沿，即control_done上升沿
	//传输状态信号
	reg status_register;	//status传输状态寄存器
	//新加入
	wire        			   control_done1;  
//=======================================================
//例化
//=======================================================

//例化ddr3_write
ddr3_write #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH),
    .AVALON_DATA_WIDTH   (AVALON_DATA_WIDTH),
    .MEMORY_BASED_FIFO   (MEMORY_BASED_FIFO),
    .FIFO_DEPTH          (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2     (FIFO_DEPTH_LOG2),
    .ADDRESS_WIDTH       (ADDRESS_WIDTH),
    .BURST_CAPABLE       (BURST_CAPABLE),
    .MAXIMUM_BURST_COUNT (MAXIMUM_BURST_COUNT),
    .BURST_COUNT_WIDTH   (BURST_COUNT_WIDTH)
) ddr3_write_0 (
    .clk                    (clk),                                     
    .reset_n                (reset_n),      		 //低电平复位         
    .soft_reset             (soft_reset),   		 //高电平复位
	//control接口
    .control_write_base     (dvp_address),    //写地址
    .control_write_length   (control_write_length),  //写长度
    .control_done           (control_done),          //写完信号
    .control_fixed_location (),             
    .control_go             (control_go),            //开始写信号
	//user接口
    .user_write_clk         (user_write_clk),    	 //写时钟    
    .user_write_buffer      (user_write_buffer), 	 //写请求      
    .user_buffer_data       (user_buffer_data),  	 //写数据   
    .user_buffer_full       (user_buffer_full),      
	//avalon_mm_master接口
    .master_address         (master_address),        
    .master_write           (master_write),          
    .master_byteenable      (master_byteenable),     
    .master_writedata       (master_writedata),      
    .master_burstcount      (master_burstcount),     
    .master_waitrequest     (master_waitrequest)     
);

//例化resize_ddr3_write
ddr3_write #(
    .USER_DATA_WIDTH     (RESIZE_USER_DATA_WIDTH),
    .AVALON_DATA_WIDTH   (AVALON_DATA_WIDTH),
    .MEMORY_BASED_FIFO   (MEMORY_BASED_FIFO),
    .FIFO_DEPTH          (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2     (FIFO_DEPTH_LOG2),
    .ADDRESS_WIDTH       (ADDRESS_WIDTH),
    .BURST_CAPABLE       (BURST_CAPABLE),
    .MAXIMUM_BURST_COUNT (MAXIMUM_BURST_COUNT),
    .BURST_COUNT_WIDTH   (BURST_COUNT_WIDTH)
) resize_ddr3_write_0 (
    .clk                    (clk),                                     
    .reset_n                (reset_n),      		 //低电平复位         
    .soft_reset             (soft_reset),   		 //高电平复位
	//control接口
    .control_write_base     (dvp_address+4*LENGTH),    //写地址
    .control_write_length   (RESIZE_LENGTH),  //写长度
    .control_done           (control_done1),          //写完信号
    .control_fixed_location (),             
    .control_go             (control_go),            //开始写信号
	//user接口
    .user_write_clk         (resize_pclk),    	 //写时钟    
    .user_write_buffer      (resize_wr_en), 	 //写请求      
    .user_buffer_data       (resize_data_out),  	 //写数据   
    .user_buffer_full       (),      
	//avalon_mm_master接口
    .master_address         (master_address1),        
    .master_write           (master_write1),          
    .master_byteenable      (master_byteenable1),     
    .master_writedata       (master_writedata1),      
    .master_burstcount      (master_burstcount1),     
    .master_waitrequest     (master_waitrequest1)     
);

//例化dvp_ddr3_ctrl
dvp_ddr3_ctrl dvp_ddr3_ctrl_0 (
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
	.control_user_base   (control_write_base),    
	.control_user_length (control_write_length),  
	.control_go          (hps_start_cap),  			//hps写一帧脉冲
	.control_en          (master_ctrl_en),  		//预留控制寄存器
	.control_state       (buffer_status)            		//传输状态
);

//例化dvp_rgb888
dvp_rgb888 #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH)
)
dvp_rgb888_inst(
    .sys_rst_n       	(reset_n     ),  	 	 //复位信号，低电平
	//dvp时序输入接口
    .dvp_pclk        	(dvp_pclk    ), 	     //摄像头像素时钟
    .dvp_href        	(dvp_href    ),     	 //摄像头行同步信号
    .dvp_vsync       	(dvp_vsync   ), 	 	 //摄像头场同步信号
    .dvp_data        	(dvp_data    ), 	 	 //摄像头图像数据
	//数据
    .rgb888_wr_en       (rgb888_wr_en   ),   	 //图像数据有效使能信号
    .rgb888_data_out    (rgb888_data_out),   	 //图像数据
	//场同步边沿
	.cmos_vsync_begin   (cmos_vsync_begin),  	 //场同步开始
    .cmos_vsync_end     (cmos_vsync_end   )   	 //场同步结束
);

//例化resize_top
resize_top  #(
    .USER_DATA_WIDTH     (RESIZE_USER_DATA_WIDTH)
 )
 resize_top_inst(
    .sys_rst_n          (reset_n     ),  //复位信号

    .dvp_pclk_in        (dvp_pclk     ),  //摄像头像素时钟
    .dvp_href_in        (dvp_href    ),  //摄像头行同步信号
    .dvp_vsync_in       (dvp_vsync   ),  //摄像头场同步信号
    .dvp_data_in        (dvp_data    ),  //摄像头图像数据

	.resize_pclk		(resize_pclk),  
    .resize_wr_en       (resize_wr_en),  //图像数据有效使能信号
    .resize_data_out    (resize_data_out),   //图像数据

    .cmos_vsync_begin   (resize_vsync_begin   ),    //场同步开始
    .cmos_vsync_end     (resize_vsync_end   )    //场同步结束
);


//=======================================================
//控制逻辑
//=======================================================

//组合逻辑赋值
assign user_write_clk=dvp_pclk;//写时钟为dvp时钟
assign user_write_buffer=rgb888_wr_en&en_cap;//写请求由数据有效与捕捉有效信号共同作用
assign user_buffer_data=rgb888_data_out;//写数据先凑个32位
assign soft_reset=1'b0;//不使用软件复位（暂时不用）
assign dvp_done=control_done;
//dvp_pclk下的时序

	//start_cap	
	always @(posedge dvp_pclk or negedge reset_n)
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
	always @(posedge dvp_pclk or negedge reset_n)
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
	always @(posedge dvp_pclk or negedge reset_n)
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
	always @(posedge dvp_pclk or negedge reset_n)
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

	//使用边沿检测检测启动信号上升沿，只会持续一个时钟周期(别用dvp时钟检测)
	always @(posedge clk or negedge reset_n)begin
			if(reset_n == 1'b0)begin
				D <= 2'b00;
			end
			else begin
				D <= {D[0], dvp_go};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
			end
		end
	assign  pos_edge = ~D[1] & D[0];
		
	//使用边沿检测检测done信号上升沿，只会持续一个时钟周期(别用dvp时钟检测)
	always @(posedge clk or negedge reset_n)begin
			if(reset_n == 1'b0)begin
				D1 <= 2'b00;
			end
			else begin
				D1 <= {D1[0], control_done};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
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
	
endmodule

