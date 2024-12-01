/*
  Legal Notice: (C)2007 Altera Corporation. All rights reserved.  Your
  use of Altera Corporation's design tools, logic functions and other
  software and tools, and its AMPP partner logic functions, and any
  output files any of the foregoing (including device programming or
  simulation files), and any associated documentation or information are
  expressly subject to the terms and conditions of the Altera Program
  License Subscription Agreement or other applicable license agreement,
  including, without limitation, that your use is for the sole purpose
  of programming logic devices manufactured by Altera and sold by Altera
  or its authorized distributors.  Please refer to the applicable
  agreement for further details.
*/

/*

	Author:  JCJB
	Date:  11/04/2007
	
	This latency aware read master is passed a word aligned address, length in bytes,
	and a 'go' bit.  The master will continue to post reads until the length register
	reaches a value of zero.  When all the reads return the done bit will be asserted. 

	To use this master you must simply drive the control signals into this block,
	and also read the data from the exposed read FIFO.  To read from the exposed FIFO
	use the 'user_read_buffer' signal to pop data from the FIFO 'user_buffer_data'.
	The signal 'user_data_available' is asserted whenever data is available from the
	exposed FIFO.
	
*/

// altera message_off 10230


module latency_aware_read_master (
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
	user_read_clk,		//添加读时钟构成双时钟异步fifo
	user_read_buffer,
	user_buffer_data,
	user_data_available,
	
	// master inputs and outputs
	master_address,
	master_read,
	master_byteenable,
	master_readdata,
	master_readdatavalid,
	master_waitrequest
);

	parameter USER_DATAWIDTH   = 16;
	parameter AVALON_DATAWIDTH = 32;
	parameter BYTEENABLEWIDTH  = 4;
	parameter ADDRESSWIDTH     = 32;
	parameter FIFODEPTH        = 32;
	parameter FIFODEPTH_LOG2   = 5;
	parameter FIFOUSEMEMORY    = 1;  // set to 0 to use LEs instead
	
	input								clk;
	input								reset;


	// control inputs and outputs
	input								control_fixed_location;
	input	[ADDRESSWIDTH-1:0]			control_read_base;
	input	[ADDRESSWIDTH-1:0]			control_read_length;
	input								control_go;
	output wire							control_done;
	output wire							control_early_done;  // don't use this unless you know what you are doing!
	
	// user logic inputs and outputs
	input								user_read_clk;
	input								user_read_buffer;
	output wire	[USER_DATAWIDTH-1:0]	user_buffer_data;
	output wire							user_data_available;
	
	// master inputs and outputs
	input								master_waitrequest;
	input								master_readdatavalid;
    input	[AVALON_DATAWIDTH-1:0]		master_readdata;
	output wire	[ADDRESSWIDTH-1:0]		master_address;
	output wire							master_read;
	output wire	[BYTEENABLEWIDTH-1:0]	master_byteenable;
	
	// internal control signals
	reg								control_fixed_location_d1;
	wire							fifo_empty;
	reg	[ADDRESSWIDTH-1:0]			address;
	reg	[ADDRESSWIDTH-1:0]			length;
	reg	[FIFODEPTH_LOG2-1:0]		reads_pending;
	wire							increment_address;
	wire							too_many_pending_reads;
	reg								too_many_pending_reads_d1;
	wire[FIFODEPTH_LOG2-1:0]		fifo_used;
	wire	                      	fifo_reset;



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
	assign master_address = address;
	assign master_byteenable = -1;  // all ones, always performing word size accesses
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
				address <= address + BYTEENABLEWIDTH;  // always performing word size accesses
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
				length <= length - BYTEENABLEWIDTH;  // always performing word size accesses
			end
		end
	end	
	
	
	
	// control logic
	//too_many_pending_reads表示产生较多的等待信号，这里时为了保证读请求不会一直读下去，
	//至少在datavalid生效之前保持4个，直到datavalid生效后且产生了(FIFODEPTH - 4)个有效
	//数据再开始读最后4个剩下的数据
	assign too_many_pending_reads = (fifo_used + reads_pending) >= (FIFODEPTH - 4);
	assign master_read = (length != 0) & (too_many_pending_reads_d1 == 0);
	assign increment_address = (length != 0) & (too_many_pending_reads_d1 == 0) & (master_waitrequest == 0);
	assign control_done = (reads_pending == 0) & (length == 0);  // master done posting reads and all reads have returned
	assign control_early_done = (length == 0);  // if you need all the pending reads to return then use 'control_done' instead of this signal
	assign fifo_reset = (control_go==1)?1'b1:1'b0;

	always @ (posedge clk)
	begin
		if (reset == 1)
		begin
			too_many_pending_reads_d1 <= 0;
		end
		else
		begin
			too_many_pending_reads_d1 <= too_many_pending_reads;
		end
	end

	

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
					reads_pending <= reads_pending + 1;
				end
				else
				begin
					reads_pending <= reads_pending;  // a read was posted, but another returned
				end			
			end
			else
			begin
				if(master_readdatavalid == 0)
				begin
					reads_pending <= reads_pending;  // read was not posted and no read returned
				end
				else
				begin
					reads_pending <= reads_pending - 1;  // read was not posted but a read returned
				end				
			end
		end
	end

	
	// read data feeding user logic	
	assign user_data_available = !fifo_empty;
	dcfifo_mixed_widths the_master_to_user_fifo (
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
		the_master_to_user_fifo.lpm_type = "dcfifo_mixed_widths",
		the_master_to_user_fifo.lpm_width = AVALON_DATAWIDTH,
		the_master_to_user_fifo.lpm_widthu = FIFODEPTH_LOG2,
		the_master_to_user_fifo.lpm_widthu_r = (AVALON_DATAWIDTH >= USER_DATAWIDTH)? FIFODEPTH_LOG2 + (AVALON_DATAWIDTH/USER_DATAWIDTH) - 1 : FIFODEPTH_LOG2 - (USER_DATAWIDTH/AVALON_DATAWIDTH) + 1,
		the_master_to_user_fifo.lpm_width_r = USER_DATAWIDTH,
		the_master_to_user_fifo.overflow_checking = "ON",
		the_master_to_user_fifo.rdsync_delaypipe = 4,
		the_master_to_user_fifo.read_aclr_synch = "ON",
		the_master_to_user_fifo.underflow_checking = "ON",
		the_master_to_user_fifo.use_eab = (FIFOUSEMEMORY == 1)? "ON" : "OFF",
		the_master_to_user_fifo.write_aclr_synch = "ON",
		the_master_to_user_fifo.wrsync_delaypipe = 4;

endmodule
