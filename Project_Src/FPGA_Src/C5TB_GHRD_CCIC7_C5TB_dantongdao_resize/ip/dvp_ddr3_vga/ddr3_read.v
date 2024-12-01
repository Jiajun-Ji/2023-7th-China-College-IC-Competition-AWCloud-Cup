module ddr3_read
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
	parameter BURST_COUNT_WIDTH = 5		//突发长度位宽+1
)
(
	clk,
	reset_n,//硬件低电平输入复位
	soft_reset,//软件复位,高电平有效
	//control控制接口
	control_fixed_location,
	control_read_base,
	control_read_length,
	control_go,
	control_done,
	control_early_done,
	//user接口
	user_read_clk,
	user_read_buffer,
	user_buffer_data,
	user_data_available,
	//avalon_mm_master接口
	master_address,
	master_read,
	master_byteenable,
	master_readdata,
	master_readdatavalid,
	master_burstcount,
	master_waitrequest
);

//输入输出定义
	input								clk;
	input								reset_n;
	input								soft_reset;
	//control控制接口
	input								control_fixed_location;
	input	[ADDRESS_WIDTH-1:0]			control_read_base;
	input	[ADDRESS_WIDTH-1:0]			control_read_length;
	input								control_go;
	output wire							control_done;
	output wire							control_early_done;  // don't use this unless you know what you are doing, it's going to fire when the last read is posted, not when the last data returns!
	//user接口
	input								user_read_buffer;			// for write master
	input								user_read_clk;	
	output wire	[USER_DATA_WIDTH-1:0]	user_buffer_data;		// for write master
	output wire							user_data_available;			// for write master
	
	//avalon_mm_master接口
	output wire	[ADDRESS_WIDTH-1:0]			master_address;
	output wire								master_read;				// for write master
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable;
	input wire	[AVALON_DATA_WIDTH-1:0]		master_readdata;			// for write master
	input									master_readdatavalid;
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount;			// for bursting read and write masters
	input									master_waitrequest;
	
//赋值
	assign reset= soft_reset||(~reset_n);
	


//例化读主机
	generate
		if(BURST_CAPABLE == 1) begin
			burst_read_master a_burst_read_master(
				.clk                    (clk),
				.reset                  (reset),//高电平复位
				
				.control_fixed_location (control_fixed_location),
				.control_read_base      (control_read_base),
				.control_read_length    (control_read_length),
				.control_go             (control_go),
				.control_done           (control_done),
				.control_early_done     (control_early_done),
				
				.user_read_clk			(user_read_clk),
				.user_read_buffer       (user_read_buffer),
				.user_buffer_data       (user_buffer_data),
				.user_data_available    (user_data_available),
				
				.master_address         (master_address),
				.master_read            (master_read),
				.master_byteenable      (master_byteenable),
				.master_readdata        (master_readdata),
				.master_readdatavalid   (master_readdatavalid),
				.master_burstcount      (master_burstcount),
				.master_waitrequest     (master_waitrequest)
			);
			defparam a_burst_read_master.DATAWIDTH = USER_DATA_WIDTH;
			defparam a_burst_read_master.MAXBURSTCOUNT = MAXIMUM_BURST_COUNT;
			defparam a_burst_read_master.BURSTCOUNTWIDTH = BURST_COUNT_WIDTH;
			defparam a_burst_read_master.BYTEENABLEWIDTH = AVALON_DATA_WIDTH/8;
			defparam a_burst_read_master.ADDRESSWIDTH = ADDRESS_WIDTH;
			defparam a_burst_read_master.FIFODEPTH = FIFO_DEPTH;
			defparam a_burst_read_master.FIFODEPTH_LOG2 = FIFO_DEPTH_LOG2;
			defparam a_burst_read_master.FIFOUSEMEMORY = MEMORY_BASED_FIFO;
		end
		else begin
			latency_aware_read_master a_latency_aware_read_master(
				.clk                    (clk),
				.reset                  (reset),
				
				.control_fixed_location (control_fixed_location),
				.control_read_base      (control_read_base),
				.control_read_length    (control_read_length),
				.control_go             (control_go),
				.control_done           (control_done),
				.control_early_done     (control_early_done),
				
				.user_read_clk			(user_read_clk),
				.user_read_buffer       (user_read_buffer),
				.user_buffer_data       (user_buffer_data),
				.user_data_available    (user_data_available),
				
				.master_address         (master_address),
				.master_read            (master_read),
				.master_byteenable      (master_byteenable),
				.master_readdata        (master_readdata),
				.master_readdatavalid   (master_readdatavalid),
				.master_waitrequest     (master_waitrequest)
			);
			defparam a_latency_aware_read_master.USER_DATAWIDTH = USER_DATA_WIDTH;
			defparam a_latency_aware_read_master.AVALON_DATAWIDTH = AVALON_DATA_WIDTH;
			defparam a_latency_aware_read_master.BYTEENABLEWIDTH = AVALON_DATA_WIDTH/8;
			defparam a_latency_aware_read_master.ADDRESSWIDTH = ADDRESS_WIDTH;
			defparam a_latency_aware_read_master.FIFODEPTH = FIFO_DEPTH;
			defparam a_latency_aware_read_master.FIFODEPTH_LOG2 = FIFO_DEPTH_LOG2;
			defparam a_latency_aware_read_master.FIFOUSEMEMORY = MEMORY_BASED_FIFO;
		end
	endgenerate
endmodule 


