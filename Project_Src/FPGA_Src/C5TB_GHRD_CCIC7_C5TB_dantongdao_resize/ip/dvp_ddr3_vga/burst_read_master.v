module burst_read_master (
	clk,
	reset,

	// control inputs and outputs
	control_fixed_location,
	control_read_base,
	control_read_length,
	control_go,
	control_done,
	control_early_done,
	
	// user logic inputs and outputs
	user_read_clk,
	user_read_buffer,
	user_buffer_data,
	user_data_available,
	
	// master inputs and outputs
	master_address,
	master_read,
	master_byteenable,
	master_readdata,
	master_readdatavalid,
	master_burstcount,
	master_waitrequest
);

	parameter DATAWIDTH = 32;
	parameter MAXBURSTCOUNT = 4;
	parameter BURSTCOUNTWIDTH = 3;
	parameter BYTEENABLEWIDTH = 4;
	parameter ADDRESSWIDTH = 32;
	parameter FIFODEPTH = 32;
	parameter FIFODEPTH_LOG2 = 5;
	parameter FIFOUSEMEMORY = 1;  // set to 0 to use LEs instead
	
	input								clk;
	input								reset;


	// control inputs and outputs
	input								control_fixed_location;
	input	[ADDRESSWIDTH-1:0]			control_read_base;
	input	[ADDRESSWIDTH-1:0]			control_read_length;
	input								control_go;
	output wire							control_done;
	output wire							control_early_done;  // don't use this unless you know what you are doing, it's going to fire when the last read is posted, not when the last data returns!
	
	// user logic inputs and outputs
	input								user_read_clk;
	input								user_read_buffer;
	output wire	[DATAWIDTH-1:0]			user_buffer_data;
	output wire							user_data_available;
	
	// master inputs and outputs
	input								master_waitrequest;
	input								master_readdatavalid;
    input	[DATAWIDTH-1:0]				master_readdata;
	output wire	[ADDRESSWIDTH-1:0]		master_address;
	output wire							master_read;
	output wire	[BYTEENABLEWIDTH-1:0]	master_byteenable;
	output wire	[BURSTCOUNTWIDTH-1:0]	master_burstcount;
	
	// internal control signals
	reg								control_fixed_location_d1;
	wire							fifo_empty;
	reg	[ADDRESSWIDTH-1:0]			address;
	reg	[ADDRESSWIDTH-1:0]			length;
	reg	[FIFODEPTH_LOG2-1:0]		reads_pending;
	wire							increment_address;
	wire	[BURSTCOUNTWIDTH-1:0]	burst_count;
	wire	[BURSTCOUNTWIDTH-1:0]	first_short_burst_count;
	wire							first_short_burst_enable;
	wire	[BURSTCOUNTWIDTH-1:0]	final_short_burst_count;
	wire							final_short_burst_enable;
	wire	[BURSTCOUNTWIDTH-1:0]	burst_boundary_word_address;
	reg								burst_begin;
	wire							too_many_reads_pending;
	reg								too_many_reads_pending_d1;
	wire	[FIFODEPTH_LOG2-1:0]	fifo_used;
	wire	                      	fifo_reset;  // watermark of the FIFO, it has a latency of 2 cycles



	// registering the control_fixed_location bit
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			control_fixed_location_d1 <= 0;
		end
		else
		begin
			if (control_go == 1)
			begin
				control_fixed_location_d1 <= control_fixed_location;
			end
		end
	end



	// master address logic 
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			address <= 0;
		end
		else
		begin
			if(control_go == 1)
			begin
				address <= control_read_base;
			end
			else if((increment_address == 1) & (control_fixed_location_d1 == 0))
			begin
				address <= address + (burst_count * BYTEENABLEWIDTH);  // always performing word size accesses, increment by the burst count presented
			end
		end
	end



	// master length logic
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			length <= 0;
		end
		else
		begin
			if(control_go == 1)
			begin
				length <= control_read_length;
			end
			else if(increment_address == 1)
			begin
				length <= length - (burst_count * BYTEENABLEWIDTH);  // always performing word size accesses, decrement by the burst count presented
			end
		end
	end	
	


	// controlled signals going to the master/control ports
	assign master_address = address;
	assign master_byteenable = -1;  // all ones, always performing word size accesses
	assign master_burstcount = burst_count;
	assign control_done = (length == 0) & (reads_pending == 0);  // need to make sure that the reads have returned before firing the done bit
	assign control_early_done = (length == 0);  // advanced feature, you should use 'control_done' if you need all the reads to return first
	assign master_read = (too_many_reads_pending == 0) & (length != 0);
	assign increment_address = (too_many_reads_pending == 0) & (master_waitrequest == 0) & (length != 0);
	assign too_many_reads_pending = (reads_pending + fifo_used) >= (FIFODEPTH -MAXBURSTCOUNT- 4);  // make sure there are fewer reads posted than room in the FIFO

	//为第一次突发准备
	assign burst_boundary_word_address = ((address / BYTEENABLEWIDTH) & (MAXBURSTCOUNT - 1));
	assign first_short_burst_enable = (burst_boundary_word_address != 0);
	assign final_short_burst_enable = (length < (MAXBURSTCOUNT * BYTEENABLEWIDTH));
	
	assign first_short_burst_count = ((burst_boundary_word_address & 1'b1) == 1'b1)? 1 :  // if the burst boundary isn't a multiple of 2 then must post a burst of 1 to get to a multiple of 2 for the next burst
									  (((MAXBURSTCOUNT - burst_boundary_word_address) < (length / BYTEENABLEWIDTH))?
									  (MAXBURSTCOUNT - burst_boundary_word_address) : (length / BYTEENABLEWIDTH));
	assign final_short_burst_count = (length / BYTEENABLEWIDTH);
	//官方
	// assign burst_count = (first_short_burst_enable == 1)? first_short_burst_count :  // this will get the transfer back on a burst boundary, 
						 // (final_short_burst_enable == 1)? final_short_burst_count : MAXBURSTCOUNT;
	//自己加的
	assign burst_count = MAXBURSTCOUNT;

	
	
	// tracking FIFO
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			reads_pending <= 0;
		end
		else
		begin
			if(increment_address == 1)
			begin
				if(master_readdatavalid == 0)
				begin
					reads_pending <= reads_pending + burst_count;
				end
				else
				begin
					reads_pending <= reads_pending + burst_count - 1;  // a burst read was posted, but a word returned
				end			
			end
			else
			begin
				if(master_readdatavalid == 0)
				begin
					reads_pending <= reads_pending;  // burst read was not posted and no read returned
				end
				else
				begin
					reads_pending <= reads_pending - 1;  // burst read was not posted but a word returned
				end				
			end
		end
	end
	assign fifo_reset = (control_go==1)?1'b1:1'b0;
	
	
	//丢弃前三个readdatavalid周期的数据
	// //检测master_readdatavalid有效信号上升沿
	// reg [1:0]D3;
	// wire GO_edge;
	// always @(posedge clk or posedge reset)begin
		// if(reset == 1'b1)begin
			// D3 <= 2'b00;
		// end
		// else begin
			// D3 <= {D3[0], master_readdatavalid};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
		// end
		// end
	// assign  GO_edge = ~D3[1] & D3[0];
	
	// //计数上升沿
	// reg [31:0]cnt;
	// always @ (posedge clk or posedge reset)
		// if (reset == 1)
			// cnt<=0;
		// else if(control_go == 1)
			// cnt<=0;
		// else if(GO_edge == 1)
			// cnt<=cnt+1;
		// else
			// cnt<=cnt;
			
	// //当flag为0同时cnt<=2时，flag=0，当cnt大于2时flag等于1
	// reg flag;		
	// always @ (posedge clk or posedge reset)
		// if (reset == 1)
			// flag<=0;
		// else if(cnt <= 2&&flag==0)
			// flag<=0;
		// else if(control_go == 1)
			// flag<=0;
		// else 
			// flag<=1;
	//结束
	
	// // //与无突发看齐
	// always @ (posedge clk)
	// begin
		// if (reset == 1)
		// begin
			// too_many_reads_pending_d1 <= 0;
		// end
		// else
		// begin
			// too_many_reads_pending_d1 <= too_many_reads_pending;
		// end
	// end
	
	
	
	// read data feeding user logic	
	assign user_data_available = !fifo_empty;
	dcfifo the_master_to_user_fifo (
		.rdclk   (user_read_clk),
		.wrclk   (clk),
		.wrreq   (master_readdatavalid),
		.aclr    (fifo_reset|reset),
		.data    (master_readdata),
		.rdreq   (user_read_buffer),
		.q       (user_buffer_data),
		.rdempty (fifo_empty),
		.wrusedw (fifo_used),
		.rdfull  (),
		.rdusedw (),
		.wrempty (),
		.wrfull  ()
	);

	defparam
		the_master_to_user_fifo.intended_device_family = "Cyclone IV E",
		the_master_to_user_fifo.lpm_numwords = FIFODEPTH,
		the_master_to_user_fifo.lpm_showahead = "ON",
		the_master_to_user_fifo.lpm_type = "dcfifo",
		the_master_to_user_fifo.lpm_width = DATAWIDTH,
		the_master_to_user_fifo.lpm_widthu = FIFODEPTH_LOG2,
		the_master_to_user_fifo.overflow_checking = "ON",
		the_master_to_user_fifo.rdsync_delaypipe = 4,
		the_master_to_user_fifo.read_aclr_synch = "ON",
		the_master_to_user_fifo.underflow_checking = "ON",
		the_master_to_user_fifo.use_eab = (FIFOUSEMEMORY == 1)? "ON" : "OFF",
		the_master_to_user_fifo.write_aclr_synch = "ON",
		the_master_to_user_fifo.wrsync_delaypipe = 4;
endmodule
