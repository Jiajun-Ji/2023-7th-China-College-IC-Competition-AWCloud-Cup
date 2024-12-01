module student(
		////////////////////////////////
		// AIEP专用信号 begin          //
		// 请不要修改                  //
		//////////// CLOCK    //////////
      input              fpga_clk_50,
		//////////// RESET    //////////
      input              fpga_rst_n,
       /////////// Buttons  //////////  		//KEY is Low-Active
      input    [ 2: 0]   usr_key_i, 	
      //////////// Swtiches //////////
      input    [ 2: 0]   usr_sw_i,
      //////////// LED 		 //////////			//LED is High-Active 
      output   [ 7: 0]   usr_led_o,
      //////////// SEG 		 //////////			//SEG is Low-Active 
      output   [ 7: 0]   usr_seg_o
		// AIEP专用信号 end            //
		////////////////////////////////
);

localparam 	NUM_0 = {1'b0, 7'h40},
			NUM_1 = {1'b1, 7'h79},
			NUM_2 = {1'b0, 7'h24},
			NUM_3 = {1'b1, 7'h30},
			NUM_4 = {1'b0, 7'h19},
			NUM_5 = {1'b1, 7'h12},
			NUM_6 = {1'b0, 7'h02},
			NUM_7 = {1'b1, 7'h78},
			NUM_8 = {1'b0, 7'h00},
			NUM_9 = {1'b1, 7'h10},
			NUM_A = {1'b0, 7'h08},
			NUM_B = {1'b1, 7'h03},
			NUM_C = {1'b0, 7'h46},
			NUM_D = {1'b1, 7'h21},
			NUM_E = {1'b0, 7'h06},
			NUM_F = {1'b1, 7'h0e};

reg  [ 4:0]		number;
reg  [31:0]     timer;
reg  [ 7:0]		 usr_led_r;
reg  [ 7:0]		usr_seg_r;
wire [ 5:0]		 input_state/*synthesis keep*/;
reg  [ 5:0]     input_state_r/*synthesis keep*/;
wire            input_state_changed/*synthesis keep*/;

assign input_state[5:3] = usr_key_i;
assign input_state[2:0] = usr_sw_i;
assign input_state_changed = input_state != input_state_r;
assign usr_led_o[7:0]   = usr_led_r;
assign usr_seg_o[7:0]	= usr_seg_r;

always@(posedge fpga_clk_50 or negedge fpga_rst_n)
begin
	if (!fpga_rst_n) begin
		input_state_r <= 6'b111111;
	end
	else begin
		input_state_r <= input_state;
	end
end

always@(posedge fpga_clk_50 or negedge fpga_rst_n)
begin
	if (!fpga_rst_n) begin
		timer <= 32'd0;
		number <= 5'd0;
	end
	else begin
		if (timer == 32'd49_999_999) begin
			timer <= 32'd0;
			if(number >= 5'd15)
				number <= 5'd0;
			else
				number <= number + 5'd1;
		end
		else begin
			timer <= timer + 32'd1;
			number <= number;
		end
	end
end

// SEG control
always@(posedge fpga_clk_50 or negedge fpga_rst_n)
begin
	if (!fpga_rst_n) begin
		usr_seg_r <= 8'b11111111;
	end
	else begin
		case(number)
			0: usr_seg_r <= NUM_0;
			1: usr_seg_r <= NUM_1;
			2: usr_seg_r <= NUM_2;
			3: usr_seg_r <= NUM_3;
			4: usr_seg_r <= NUM_4;
			5: usr_seg_r <= NUM_5;
			6: usr_seg_r <= NUM_6;
			7: usr_seg_r <= NUM_7;
			8: usr_seg_r <= NUM_8;
			9: usr_seg_r <= NUM_9;
			10: usr_seg_r <= NUM_A;
			11: usr_seg_r <= NUM_B;
			12: usr_seg_r <= NUM_C;
			13: usr_seg_r <= NUM_D;
			14: usr_seg_r <= NUM_E;
			15: usr_seg_r <= NUM_F;
			default: usr_seg_r <= 8'b11111111;
		endcase
	end
end

// LED control
always@(posedge fpga_clk_50 or negedge fpga_rst_n)
begin
	if (!fpga_rst_n) begin
		usr_led_r <= 8'b00000011;
	end
	else begin
		case(input_state)
			6'b011111: begin // KEY2: 全亮
				usr_led_r <= 8'b11111111;
			end
			6'b101111: begin // KEY1: LED7 5 3 1亮
				usr_led_r <= 8'b10101010;
			end
			6'b110111: begin // KEY0: LED6 4 2 0亮
				usr_led_r <= 8'b01010101;
			end
			6'b111011: begin // SW2: 流水灯
				if(input_state_changed) begin
					usr_led_r <= 8'b00000001;
				end
				else begin
					if(timer == 32'd49_999_999) begin
						usr_led_r <= {usr_led_r[6:0], usr_led_r[7]};
					end
					else begin
						usr_led_r <= usr_led_r;
					end
				end
			end
			6'b111101: begin // SW1: 反向流水灯
				if(input_state_changed) begin
					usr_led_r <= 8'b10000000;
				end
				else begin
					if(timer == 32'd49_999_999) begin
						usr_led_r <= {usr_led_r[0], usr_led_r[7:1]};
					end
					else begin
						usr_led_r <= usr_led_r;
					end
				end
			end
			6'b111110: begin // SW0: 全闪缩
				if(input_state_changed) begin
					usr_led_r <= 8'd0;
				end
				else begin
					if(timer == 32'd49_999_999) begin
						usr_led_r <= ~usr_led_r;
					end
					else begin
						usr_led_r <= usr_led_r;
					end
				end
			end
            default: begin // 双灯流水
                if(input_state_changed) begin
					usr_led_r <= 8'b00000011;
				end
				else begin
					if(timer == 32'd49_999_999) begin
						usr_led_r <= {usr_led_r[5:0], usr_led_r[7:6]};
					end
					else begin
						usr_led_r <= usr_led_r;
					end
				end
            end
		endcase
	end
end

endmodule
