module bin2bcd
(
	input wire clk, 
	input wire rst_n,
	input wire start,
	input wire [15:0] bin,
	output reg ready, 
	output reg done_tick,
	output wire [3:0] bcd4, 
	output wire [3:0] bcd3, 
	output wire [3:0] bcd2, 
	output wire [3:0] bcd1, 
	output wire [3:0] bcd0
);

 //符号状态说明
 localparam [1:0]
	 idle = 2'b00,
	 op = 2'b01,
	 done = 2'b10;
 
 //信号说明
 reg [1:0] state_reg, state_next;
 reg [15:0] p2s_reg, p2s_next;
 reg [4:0] n_reg, n_next;
 reg [3:0] bcd4_reg, bcd3_reg, bcd2_reg, bcd1_reg, bcd0_reg;
 reg [3:0] bcd4_next, bcd3_next, bcd2_next, bcd1_next, bcd0_next;
 wire [3:0] bcd4_tmp, bcd3_tmp, bcd2_tmp, bcd1_tmp, bcd0_tmp;
 
 //FSMD状态和数据记录
 always@(posedge clk or negedge rst_n)
 begin
	if(!rst_n)
	 begin
		 state_reg <= idle;
		 p2s_reg <= 16'd0;
		 n_reg <= 4'd0;
		 bcd4_reg <= 4'h0;
		 bcd3_reg <= 4'h0;
		 bcd2_reg <= 4'h0;
		 bcd1_reg <= 4'h0;
		 bcd0_reg <= 4'h0; 
	 end
	 else
	 begin
		 state_reg <= state_next;
		 p2s_reg <= p2s_next;
		 n_reg <= n_next;
		 bcd4_reg <= bcd4_next;
		 bcd3_reg <= bcd3_next;
		 bcd2_reg <= bcd2_next;
		 bcd1_reg <= bcd1_next;
		 bcd0_reg <= bcd0_next;
  end
 end
 
 //FSMD下一状态逻辑
 always@(*)
 begin
	 state_next = state_reg;
	 p2s_next = p2s_reg;
	 n_next = n_reg;
	 bcd4_next = bcd4_reg;
	 bcd3_next = bcd3_reg;
	 bcd2_next = bcd2_reg;
	 bcd1_next = bcd1_reg;
	 bcd0_next = bcd0_reg;
	 ready = 1'b0;
	 done_tick = 1'b0;
	 
	 case(state_reg)
	 idle:
		 begin
			 ready = 1'b1;
			 if(start)
			 begin
				 state_next = op;
				 bcd4_next = 4'h0;
				 bcd3_next = 4'h0;
				 bcd2_next = 4'h0;
				 bcd1_next = 4'h0;
				 bcd0_next = 4'h0;
				 n_next = 5'd16; //索引
				 p2s_next = bin; //移位寄存器
			 end 
		 end 
	 op:
		 begin
		 //二进制位移位
		 p2s_next = p2s_reg << 1;
		 bcd0_next = {bcd0_tmp[2:0], p2s_next[15]};
		 bcd1_next = {bcd1_tmp[2:0], bcd0_tmp[3]};
		 bcd2_next = {bcd2_tmp[2:0], bcd1_tmp[3]};
		 bcd3_next = {bcd3_tmp[2:0], bcd2_tmp[3]};
		 bcd4_next = {bcd4_tmp[2:0], bcd3_tmp[3]};
		 n_next = n_reg - 1'b1;
		 if(n_next == 1)
		 begin
			state_next = done;
		 end 
	 end 
	 done:
		 begin
			 done_tick = 1'b1;
			 state_next = idle;
		 end 
		default: state_next = idle;
		
	 endcase
end
 
 //数据通路功能单元
 //数据的调整
 assign bcd0_tmp = (bcd0_reg > 4) ? bcd0_reg + 4'h3 : bcd0_reg;
 assign bcd1_tmp = (bcd1_reg > 4) ? bcd1_reg + 4'h3 : bcd1_reg;
 assign bcd2_tmp = (bcd2_reg > 4) ? bcd2_reg + 4'h3 : bcd2_reg;
 assign bcd3_tmp = (bcd3_reg > 4) ? bcd3_reg + 4'h3 : bcd3_reg;
 assign bcd4_tmp = (bcd4_reg > 4) ? bcd4_reg + 4'h3 : bcd4_reg;
 //输出
 assign bcd0 = bcd0_reg;
 assign bcd1 = bcd1_reg;
 assign bcd2 = bcd2_reg;
 assign bcd3 = bcd3_reg;
 assign bcd4 = bcd4_reg;

endmodule
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 