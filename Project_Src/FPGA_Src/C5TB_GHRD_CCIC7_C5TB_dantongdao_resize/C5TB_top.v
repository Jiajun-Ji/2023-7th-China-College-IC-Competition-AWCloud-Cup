module C5TB_top(

//====================HPS=================================== 
      output   [14: 0]   HPS_DDR3_ADDR,		//## HPS_DDR3 ##
      output   [ 2: 0]   HPS_DDR3_BA,
      output             HPS_DDR3_CAS_n,
      output   [ 0: 0]   HPS_DDR3_CKE,
      output             HPS_DDR3_CK_n,
      output             HPS_DDR3_CK_p,
      output   [ 0: 0]   HPS_DDR3_CS_n,
      output   [ 3: 0]   HPS_DDR3_DM,
      inout    [31: 0]   HPS_DDR3_DQ,
      inout    [ 3: 0]   HPS_DDR3_DQS_n,
      inout    [ 3: 0]   HPS_DDR3_DQS_p,
      output   [ 0: 0]   HPS_DDR3_ODT,
      output             HPS_DDR3_RAS_n,
      output             HPS_DDR3_RESET_n, 
      input              HPS_DDR3_RZQ,
      output             HPS_DDR3_WE_n,
      output             HPS_ENET_GTX_CLK,	//## HPS_ENET ##	
      inout              HPS_ENET_INT_n,		//hps_gpio_GPIO35
      output             HPS_ENET_MDC,
      inout              HPS_ENET_MDIO,
      input              HPS_ENET_RX_CLK,
      input    [ 3: 0]   HPS_ENET_RX_DATA,
      input              HPS_ENET_RX_DV,
      output   [ 3: 0]   HPS_ENET_TX_DATA,
      output             HPS_ENET_TX_EN,
      output             HPS_SDMMC_CLK,		//## HPS_SDMMC ##
      inout              HPS_SDMMC_CMD,
      inout    [ 3: 0]   HPS_SDMMC_DATA,
      input              HPS_UART_RX,			//## HPS_UART ##	
      output             HPS_UART_TX,					
      input              HPS_USB_CLKOUT,		//## HPS_USB ##
      inout    [ 7: 0]   HPS_USB_DATA,
      input              HPS_USB_DIR,
      input              HPS_USB_NXT,
      output             HPS_USB_STP,

		//////////// CLOCK //////////
      input              FPGA_CLK1_50,
      ///////// LED 		 /////////			//LED is High-Active 
      output   [ 9: 0]   LED,					//[ 7: 0] >> TB_LED  [9:8] >> CB_LED
	  inout    [1:0]     LOANIO_LED,					//[11:10] >> CB_HPS_LED

//==================SW6 TEST=================================
	   inout    [ 5: 0]   SW6,					//Switch 6 bit

//==================SEG TEST=================================
		output [7:0] SEG
);


/*****************************************************************************
 ↓↓                            以下区域请勿修改                  				  ↓↓
 *****************************************************************************/
//=======================================================
//  REG/WIRE declarations
//=======================================================
wire hps_fpga_reset_n;
// wire fpga_clk_50;
// wire fpga_clk_cnn;
// wire fpga_clk_stp;
wire [19:0] debug_tool_led/*synthesis keep*/;
wire [2:0] debug_tool_sw/*synthesis keep*/;
wire [2:0] debug_tool_key/*synthesis keep*/;
wire [7:0] usr_led;
wire [7:0] usr_seg;
wire [2:0] usr_sw;
wire [2:0] usr_key;

// pll_inst pll_inst0 (
		// .refclk   (FPGA_CLK1_50),   		//  refclk.clk
		// .rst      (~hps_fpga_reset_n),   //   reset.reset
		// .outclk_0 (fpga_clk_50),
		// .outclk_1 (fpga_clk_cnn),
		// .outclk_2 (fpga_clk_stp)
	// );

//=======================================================
//  Structural coding
//=======================================================
soc_system u0 (
	//Clock&Reset
	// .clk_cnn_clk (fpga_clk_cnn),                            					//  clk_150.clk
    .clk_50_clk (FPGA_CLK1_50),                             						//  clk.clk
	.reset_50_reset_n (hps_fpga_reset_n),                   					//  reset_150.reset_n
	// .reset_cnn_reset_n (hps_fpga_reset_n),                   					//  reset_50.reset_n
	 //hps_fpga_reset_n
	.hps_0_h2f_reset_reset_n (hps_fpga_reset_n),                				//  hps_0_h2f_reset.reset_n
	.hps_0_f2h_cold_reset_req_reset_n (1'b1),       								//  hps_0_f2h_cold_reset_req.reset_n
	.hps_0_f2h_debug_reset_req_reset_n (1'b1),      								//  hps_0_f2h_debug_reset_req.reset_n
	.hps_0_f2h_warm_reset_req_reset_n (1'b1),      									//  hps_0_f2h_warm_reset_req.reset_n
    //HPS ddr3
	.memory_mem_a (HPS_DDR3_ADDR),                        						//  .memory.mem_a
	.memory_mem_ba (HPS_DDR3_BA),                         						//  .mem_ba
	.memory_mem_ck (HPS_DDR3_CK_p),                       						//  .mem_ck
	.memory_mem_ck_n (HPS_DDR3_CK_n),                      						//  .mem_ck_n
	.memory_mem_cke (HPS_DDR3_CKE),                        						//  .mem_cke
	.memory_mem_cs_n (HPS_DDR3_CS_n),                      						//  .mem_cs_n
	.memory_mem_ras_n (HPS_DDR3_RAS_n),                    						//  .mem_ras_n
	.memory_mem_cas_n (HPS_DDR3_CAS_n),                    						//  .mem_cas_n
	.memory_mem_we_n (HPS_DDR3_WE_n),                      						//  .mem_we_n
	.memory_mem_reset_n (HPS_DDR3_RESET_n),                						//  .mem_reset_n
	.memory_mem_dq (HPS_DDR3_DQ),                          						//  .mem_dq
	.memory_mem_dqs (HPS_DDR3_DQS_p),                      						//  .mem_dqs
	.memory_mem_dqs_n (HPS_DDR3_DQS_n),                    						//  .mem_dqs_n
	.memory_mem_odt (HPS_DDR3_ODT),                        						//  .mem_odt
	.memory_mem_dm (HPS_DDR3_DM),                          						//  .mem_dm
	.memory_oct_rzqin (HPS_DDR3_RZQ),                         					//  .oct_rzqin
	//HPS ethernet
	.hps_0_hps_io_hps_io_emac1_inst_TX_CLK (HPS_ENET_GTX_CLK),        		//  .hps_io_emac1_inst_TX_CLK
	.hps_0_hps_io_hps_io_emac1_inst_TXD0 (HPS_ENET_TX_DATA[0]),    			//  .hps_io_emac1_inst_TXD0
	.hps_0_hps_io_hps_io_emac1_inst_TXD1 (HPS_ENET_TX_DATA[1]),    			//  .hps_io_emac1_inst_TXD1
	.hps_0_hps_io_hps_io_emac1_inst_TXD2 (HPS_ENET_TX_DATA[2]),    			//  .hps_io_emac1_inst_TXD2
	.hps_0_hps_io_hps_io_emac1_inst_TXD3 (HPS_ENET_TX_DATA[3]),    			//  .hps_io_emac1_inst_TXD3
	.hps_0_hps_io_hps_io_emac1_inst_RXD0 (HPS_ENET_RX_DATA[0]),    			//  .hps_io_emac1_inst_RXD0
	.hps_0_hps_io_hps_io_emac1_inst_MDIO (HPS_ENET_MDIO),          			//  .hps_io_emac1_inst_MDIO
	.hps_0_hps_io_hps_io_emac1_inst_MDC (HPS_ENET_MDC),         	 			//  .hps_io_emac1_inst_MDC
	.hps_0_hps_io_hps_io_emac1_inst_RX_CTL (HPS_ENET_RX_DV),          		//  .hps_io_emac1_inst_RX_CTL
	.hps_0_hps_io_hps_io_emac1_inst_TX_CTL (HPS_ENET_TX_EN),          		//  .hps_io_emac1_inst_TX_CTL
	.hps_0_hps_io_hps_io_emac1_inst_RX_CLK (HPS_ENET_RX_CLK),         		//  .hps_io_emac1_inst_RX_CLK
	.hps_0_hps_io_hps_io_emac1_inst_RXD1 (HPS_ENET_RX_DATA[1]),    			//  .hps_io_emac1_inst_RXD1
	.hps_0_hps_io_hps_io_emac1_inst_RXD2 (HPS_ENET_RX_DATA[2]),    			//  .hps_io_emac1_inst_RXD2
	.hps_0_hps_io_hps_io_emac1_inst_RXD3 (HPS_ENET_RX_DATA[3]),    			//  .hps_io_emac1_inst_RXD3
	//HPS SD card			
	.hps_0_hps_io_hps_io_sdio_inst_CMD (HPS_SDMMC_CMD),            			//	.hps_io_sdio_inst_CMD
	.hps_0_hps_io_hps_io_sdio_inst_D0 (HPS_SDMMC_DATA[0]),       				//	.hps_io_sdio_inst_D0
	.hps_0_hps_io_hps_io_sdio_inst_D1 (HPS_SDMMC_DATA[1]),       				//	.hps_io_sdio_inst_D1
	.hps_0_hps_io_hps_io_sdio_inst_CLK (HPS_SDMMC_CLK),          				//	.hps_io_sdio_inst_CLK
	.hps_0_hps_io_hps_io_sdio_inst_D2 (HPS_SDMMC_DATA[2]),       				//	.hps_io_sdio_inst_D2
	.hps_0_hps_io_hps_io_sdio_inst_D3 (HPS_SDMMC_DATA[3]),       				//	.hps_io_sdio_inst_D3
	//HPS USB	
	.hps_0_hps_io_hps_io_usb1_inst_D0 (HPS_USB_DATA[0]),       					//	.hps_io_usb1_inst_D0
	.hps_0_hps_io_hps_io_usb1_inst_D1 (HPS_USB_DATA[1]),       					//	.hps_io_usb1_inst_D1
	.hps_0_hps_io_hps_io_usb1_inst_D2 (HPS_USB_DATA[2]),       					//	.hps_io_usb1_inst_D2
	.hps_0_hps_io_hps_io_usb1_inst_D3 (HPS_USB_DATA[3]),       					//	.hps_io_usb1_inst_D3
	.hps_0_hps_io_hps_io_usb1_inst_D4 (HPS_USB_DATA[4]),       					//	.hps_io_usb1_inst_D4
	.hps_0_hps_io_hps_io_usb1_inst_D5 (HPS_USB_DATA[5]),       					//	.hps_io_usb1_inst_D5
	.hps_0_hps_io_hps_io_usb1_inst_D6 (HPS_USB_DATA[6]),       					//	.hps_io_usb1_inst_D6
	.hps_0_hps_io_hps_io_usb1_inst_D7 (HPS_USB_DATA[7]),       					//	.hps_io_usb1_inst_D7
	.hps_0_hps_io_hps_io_usb1_inst_CLK (HPS_USB_CLKOUT),        				//	.hps_io_usb1_inst_CLK
	.hps_0_hps_io_hps_io_usb1_inst_STP (HPS_USB_STP),           				//	.hps_io_usb1_inst_STP
	.hps_0_hps_io_hps_io_usb1_inst_DIR (HPS_USB_DIR),           				//	.hps_io_usb1_inst_DIR
	.hps_0_hps_io_hps_io_usb1_inst_NXT (HPS_USB_NXT),           				//	.hps_io_usb1_inst_NXT
				
	//HPS UART					
	.hps_0_hps_io_hps_io_uart0_inst_RX (HPS_UART_RX),           				//	.hps_io_uart0_inst_RX
	.hps_0_hps_io_hps_io_uart0_inst_TX (HPS_UART_TX),           				//	.hps_io_uart0_inst_TX
	//HPS GPIO		
	.hps_0_hps_io_hps_io_gpio_inst_GPIO35 (HPS_ENET_INT_n),  					//	.hps_io_gpio_inst_GPIO35
		
	//FPGA Partion	
	.led_pio_external_connection_export (debug_tool_led),                			//	.led_pio_external_connection
	.dipsw_pio_external_connection_export (debug_tool_sw),              				//	.dipsw_pio_external_connection
	.button_pio_external_connection_export (debug_tool_key),        				//	.button_pio_external_connection
	
	//Addition six HPS_GPIO         2022/06/15   by Jostm
	.hps_0_hps_io_hps_io_gpio_inst_GPIO34  (SW6[0]),  //                               .hps_io_gpio_inst_GPIO34
   	.hps_0_hps_io_hps_io_gpio_inst_GPIO48  (SW6[1]),  //                               .hps_io_gpio_inst_GPIO48
   	.hps_0_hps_io_hps_io_gpio_inst_GPIO51  (SW6[2]),  //                               .hps_io_gpio_inst_GPIO51
   	.hps_0_hps_io_hps_io_gpio_inst_GPIO52  (SW6[3]),  //                               .hps_io_gpio_inst_GPIO52
   	.hps_0_hps_io_hps_io_gpio_inst_GPIO53  (SW6[4]),  //                               .hps_io_gpio_inst_GPIO53
   	.hps_0_hps_io_hps_io_gpio_inst_GPIO54  (SW6[5]),  //                               .hps_io_gpio_inst_GPIO54

	.hps_0_hps_io_hps_io_gpio_inst_LOANIO00 (LOANIO_LED[0]), //                               .hps_io_gpio_inst_LOANIO00
    .hps_0_hps_io_hps_io_gpio_inst_LOANIO09 (LOANIO_LED[1]), //                               .hps_io_gpio_inst_LOANIO09
	.hps_0_h2f_loan_io_in                   (loan_io_in),                   //              hps_0_h2f_loan_io.in
    .hps_0_h2f_loan_io_out                  (loan_io_out),                  //                               .out
    .hps_0_h2f_loan_io_oe                   (loan_io_oe)
);

wire [66:0] loan_io_in;
wire [66:0] loan_io_out;
wire [66:0] loan_io_oe;

assign {loan_io_oe[0], loan_io_oe[9]} = 2'b11;

student u1(
		//////////// CLOCK //////////
      .fpga_clk_50(FPGA_CLK1_50),
		
		//////////// CLOCK //////////
      .fpga_rst_n(hps_fpga_reset_n),
	  
       ///////// Buttons /////////  		//KEY is Low-Active
      .usr_key_i(usr_key), 	

      ///////// Swtiches /////////
      .usr_sw_i(usr_sw),

      ///////// LED 		 /////////			//LED is High-Active 
      .usr_led_o(usr_led),						//[ 7: 0] >> TB_LED 

      ///////// SEG 		 /////////			//SEG is Low-Active 
      .usr_seg_o(usr_seg)						//[ 7: 0] >> TB_SEG 
);

	  
//=======================================================
//外设仿真软件接口
//=======================================================
reg  [31:0]     timer;
reg 				[ 11: 0]     	LED_r;	 				//仿真软件上LED灯，可以实时监控TB板上LED的状态
reg					[7:0]		SEG_r;						//仿真软件上SEG数码管，可以实时监控TB板上SEG的状态
reg				[ 2: 0]			SW_r;						//仿真软件上拨码开关，可以模拟拨码输入
reg 				[ 2: 0]			KEY_r;					//仿真软件上按键开关，可以模拟按键输入

assign			debug_tool_led[19:0] = {SEG[7:0], LED[8], loan_io_out[0], LED[9], loan_io_out[9], LED[7:0]};
assign 			LED[9:0] =	{LED_r[11], LED_r[9], LED_r[7:0]};						//LED信号输出到Port
assign			SEG[7:0] = SEG_r[7:0];
assign			{loan_io_out[9], loan_io_out[0]} = {LED_r[10], LED_r[8]};
assign			usr_key = KEY_r;							//KEY信号输入到学生编程模块
assign			usr_sw  = SW_r;							//SW信号输入到学生编程模块

always@(debug_tool_key,debug_tool_sw,usr_led,usr_seg)
begin
	KEY_r <= debug_tool_key;
	SW_r  <= debug_tool_sw;
	LED_r[7:0] <= usr_led[7:0];
	SEG_r[7:0] <= usr_seg[7:0];
end

always@(posedge FPGA_CLK1_50 or negedge hps_fpga_reset_n)
begin
	if (!hps_fpga_reset_n) begin
		timer <= 32'd0;
	end
	else begin
		if (timer == 32'd49_999_999)
			timer <= 32'd0;
		else
			timer <= timer + 32'd1;
	end
end

always@(posedge FPGA_CLK1_50 or negedge hps_fpga_reset_n)
begin
	if (!hps_fpga_reset_n) begin
		LED_r[11:8] <= 4'b0001;
	end
	else begin
		if (timer == 32'd49_999_999)
			LED_r[11:8] <= {LED_r[10:8], LED_r[11]};
		else
			LED_r[11:8] <= LED_r[11:8];
	end
end

//==============================================end===========================


endmodule


