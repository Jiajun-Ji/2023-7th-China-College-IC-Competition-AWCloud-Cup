// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


module soc_system_hps_0_hps_io_border(
// gpio_loanio
  output wire [29 - 1 : 0 ] gpio_loanio_loanio0_i
 ,input wire [29 - 1 : 0 ] gpio_loanio_loanio0_oe
 ,input wire [29 - 1 : 0 ] gpio_loanio_loanio0_o
 ,output wire [29 - 1 : 0 ] gpio_loanio_loanio1_i
 ,input wire [29 - 1 : 0 ] gpio_loanio_loanio1_oe
 ,input wire [29 - 1 : 0 ] gpio_loanio_loanio1_o
 ,output wire [9 - 1 : 0 ] gpio_loanio_loanio2_i
 ,input wire [9 - 1 : 0 ] gpio_loanio_loanio2_oe
 ,input wire [9 - 1 : 0 ] gpio_loanio_loanio2_o
// memory
 ,output wire [15 - 1 : 0 ] mem_a
 ,output wire [3 - 1 : 0 ] mem_ba
 ,output wire [1 - 1 : 0 ] mem_ck
 ,output wire [1 - 1 : 0 ] mem_ck_n
 ,output wire [1 - 1 : 0 ] mem_cke
 ,output wire [1 - 1 : 0 ] mem_cs_n
 ,output wire [1 - 1 : 0 ] mem_ras_n
 ,output wire [1 - 1 : 0 ] mem_cas_n
 ,output wire [1 - 1 : 0 ] mem_we_n
 ,output wire [1 - 1 : 0 ] mem_reset_n
 ,inout wire [32 - 1 : 0 ] mem_dq
 ,inout wire [4 - 1 : 0 ] mem_dqs
 ,inout wire [4 - 1 : 0 ] mem_dqs_n
 ,output wire [1 - 1 : 0 ] mem_odt
 ,output wire [4 - 1 : 0 ] mem_dm
 ,input wire [1 - 1 : 0 ] oct_rzqin
// hps_io
 ,output wire [1 - 1 : 0 ] hps_io_emac1_inst_TX_CLK
 ,output wire [1 - 1 : 0 ] hps_io_emac1_inst_TXD0
 ,output wire [1 - 1 : 0 ] hps_io_emac1_inst_TXD1
 ,output wire [1 - 1 : 0 ] hps_io_emac1_inst_TXD2
 ,output wire [1 - 1 : 0 ] hps_io_emac1_inst_TXD3
 ,input wire [1 - 1 : 0 ] hps_io_emac1_inst_RXD0
 ,inout wire [1 - 1 : 0 ] hps_io_emac1_inst_MDIO
 ,output wire [1 - 1 : 0 ] hps_io_emac1_inst_MDC
 ,input wire [1 - 1 : 0 ] hps_io_emac1_inst_RX_CTL
 ,output wire [1 - 1 : 0 ] hps_io_emac1_inst_TX_CTL
 ,input wire [1 - 1 : 0 ] hps_io_emac1_inst_RX_CLK
 ,input wire [1 - 1 : 0 ] hps_io_emac1_inst_RXD1
 ,input wire [1 - 1 : 0 ] hps_io_emac1_inst_RXD2
 ,input wire [1 - 1 : 0 ] hps_io_emac1_inst_RXD3
 ,inout wire [1 - 1 : 0 ] hps_io_sdio_inst_CMD
 ,inout wire [1 - 1 : 0 ] hps_io_sdio_inst_D0
 ,inout wire [1 - 1 : 0 ] hps_io_sdio_inst_D1
 ,output wire [1 - 1 : 0 ] hps_io_sdio_inst_CLK
 ,inout wire [1 - 1 : 0 ] hps_io_sdio_inst_D2
 ,inout wire [1 - 1 : 0 ] hps_io_sdio_inst_D3
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D0
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D1
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D2
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D3
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D4
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D5
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D6
 ,inout wire [1 - 1 : 0 ] hps_io_usb1_inst_D7
 ,input wire [1 - 1 : 0 ] hps_io_usb1_inst_CLK
 ,output wire [1 - 1 : 0 ] hps_io_usb1_inst_STP
 ,input wire [1 - 1 : 0 ] hps_io_usb1_inst_DIR
 ,input wire [1 - 1 : 0 ] hps_io_usb1_inst_NXT
 ,input wire [1 - 1 : 0 ] hps_io_uart0_inst_RX
 ,output wire [1 - 1 : 0 ] hps_io_uart0_inst_TX
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_GPIO34
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_GPIO35
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_GPIO48
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_GPIO51
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_GPIO52
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_GPIO53
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_GPIO54
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_LOANIO00
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_LOANIO09
);

assign hps_io_emac1_inst_MDIO = intermediate[1] ? intermediate[0] : 'z;
assign hps_io_sdio_inst_CMD = intermediate[3] ? intermediate[2] : 'z;
assign hps_io_sdio_inst_D0 = intermediate[5] ? intermediate[4] : 'z;
assign hps_io_sdio_inst_D1 = intermediate[7] ? intermediate[6] : 'z;
assign hps_io_sdio_inst_D2 = intermediate[9] ? intermediate[8] : 'z;
assign hps_io_sdio_inst_D3 = intermediate[11] ? intermediate[10] : 'z;
assign hps_io_usb1_inst_D0 = intermediate[13] ? intermediate[12] : 'z;
assign hps_io_usb1_inst_D1 = intermediate[15] ? intermediate[14] : 'z;
assign hps_io_usb1_inst_D2 = intermediate[17] ? intermediate[16] : 'z;
assign hps_io_usb1_inst_D3 = intermediate[19] ? intermediate[18] : 'z;
assign hps_io_usb1_inst_D4 = intermediate[21] ? intermediate[20] : 'z;
assign hps_io_usb1_inst_D5 = intermediate[23] ? intermediate[22] : 'z;
assign hps_io_usb1_inst_D6 = intermediate[25] ? intermediate[24] : 'z;
assign hps_io_usb1_inst_D7 = intermediate[27] ? intermediate[26] : 'z;
assign hps_io_gpio_inst_GPIO34 = intermediate[29] ? intermediate[28] : 'z;
assign hps_io_gpio_inst_GPIO35 = intermediate[31] ? intermediate[30] : 'z;
assign hps_io_gpio_inst_GPIO48 = intermediate[33] ? intermediate[32] : 'z;
assign hps_io_gpio_inst_GPIO51 = intermediate[35] ? intermediate[34] : 'z;
assign hps_io_gpio_inst_GPIO52 = intermediate[37] ? intermediate[36] : 'z;
assign hps_io_gpio_inst_GPIO53 = intermediate[39] ? intermediate[38] : 'z;
assign hps_io_gpio_inst_GPIO54 = intermediate[41] ? intermediate[40] : 'z;
assign hps_io_gpio_inst_LOANIO00 = intermediate[43] ? intermediate[42] : 'z;
assign hps_io_gpio_inst_LOANIO09 = intermediate[45] ? intermediate[44] : 'z;

wire [46 - 1 : 0] intermediate;

wire [81 - 1 : 0] floating;

cyclonev_hps_peripheral_emac emac1_inst(
 .EMAC_GMII_MDO_I({
    hps_io_emac1_inst_MDIO[0:0] // 0:0
  })
,.EMAC_GMII_MDO_OE({
    intermediate[1:1] // 0:0
  })
,.EMAC_PHY_TXD({
    hps_io_emac1_inst_TXD3[0:0] // 3:3
   ,hps_io_emac1_inst_TXD2[0:0] // 2:2
   ,hps_io_emac1_inst_TXD1[0:0] // 1:1
   ,hps_io_emac1_inst_TXD0[0:0] // 0:0
  })
,.EMAC_CLK_TX({
    hps_io_emac1_inst_TX_CLK[0:0] // 0:0
  })
,.EMAC_PHY_RXDV({
    hps_io_emac1_inst_RX_CTL[0:0] // 0:0
  })
,.EMAC_PHY_RXD({
    hps_io_emac1_inst_RXD3[0:0] // 3:3
   ,hps_io_emac1_inst_RXD2[0:0] // 2:2
   ,hps_io_emac1_inst_RXD1[0:0] // 1:1
   ,hps_io_emac1_inst_RXD0[0:0] // 0:0
  })
,.EMAC_GMII_MDO_O({
    intermediate[0:0] // 0:0
  })
,.EMAC_GMII_MDC({
    hps_io_emac1_inst_MDC[0:0] // 0:0
  })
,.EMAC_PHY_TX_OE({
    hps_io_emac1_inst_TX_CTL[0:0] // 0:0
  })
,.EMAC_CLK_RX({
    hps_io_emac1_inst_RX_CLK[0:0] // 0:0
  })
);


cyclonev_hps_peripheral_sdmmc sdio_inst(
 .SDMMC_DATA_I({
    hps_io_sdio_inst_D3[0:0] // 3:3
   ,hps_io_sdio_inst_D2[0:0] // 2:2
   ,hps_io_sdio_inst_D1[0:0] // 1:1
   ,hps_io_sdio_inst_D0[0:0] // 0:0
  })
,.SDMMC_CMD_O({
    intermediate[2:2] // 0:0
  })
,.SDMMC_CCLK({
    hps_io_sdio_inst_CLK[0:0] // 0:0
  })
,.SDMMC_DATA_O({
    intermediate[10:10] // 3:3
   ,intermediate[8:8] // 2:2
   ,intermediate[6:6] // 1:1
   ,intermediate[4:4] // 0:0
  })
,.SDMMC_CMD_OE({
    intermediate[3:3] // 0:0
  })
,.SDMMC_CMD_I({
    hps_io_sdio_inst_CMD[0:0] // 0:0
  })
,.SDMMC_DATA_OE({
    intermediate[11:11] // 3:3
   ,intermediate[9:9] // 2:2
   ,intermediate[7:7] // 1:1
   ,intermediate[5:5] // 0:0
  })
);


cyclonev_hps_peripheral_usb usb1_inst(
 .USB_ULPI_STP({
    hps_io_usb1_inst_STP[0:0] // 0:0
  })
,.USB_ULPI_DATA_I({
    hps_io_usb1_inst_D7[0:0] // 7:7
   ,hps_io_usb1_inst_D6[0:0] // 6:6
   ,hps_io_usb1_inst_D5[0:0] // 5:5
   ,hps_io_usb1_inst_D4[0:0] // 4:4
   ,hps_io_usb1_inst_D3[0:0] // 3:3
   ,hps_io_usb1_inst_D2[0:0] // 2:2
   ,hps_io_usb1_inst_D1[0:0] // 1:1
   ,hps_io_usb1_inst_D0[0:0] // 0:0
  })
,.USB_ULPI_NXT({
    hps_io_usb1_inst_NXT[0:0] // 0:0
  })
,.USB_ULPI_DIR({
    hps_io_usb1_inst_DIR[0:0] // 0:0
  })
,.USB_ULPI_DATA_O({
    intermediate[26:26] // 7:7
   ,intermediate[24:24] // 6:6
   ,intermediate[22:22] // 5:5
   ,intermediate[20:20] // 4:4
   ,intermediate[18:18] // 3:3
   ,intermediate[16:16] // 2:2
   ,intermediate[14:14] // 1:1
   ,intermediate[12:12] // 0:0
  })
,.USB_ULPI_CLK({
    hps_io_usb1_inst_CLK[0:0] // 0:0
  })
,.USB_ULPI_DATA_OE({
    intermediate[27:27] // 7:7
   ,intermediate[25:25] // 6:6
   ,intermediate[23:23] // 5:5
   ,intermediate[21:21] // 4:4
   ,intermediate[19:19] // 3:3
   ,intermediate[17:17] // 2:2
   ,intermediate[15:15] // 1:1
   ,intermediate[13:13] // 0:0
  })
);


cyclonev_hps_peripheral_uart uart0_inst(
 .UART_RXD({
    hps_io_uart0_inst_RX[0:0] // 0:0
  })
,.UART_TXD({
    hps_io_uart0_inst_TX[0:0] // 0:0
  })
);


cyclonev_hps_peripheral_gpio gpio_inst(
 .GPIO1_PORTA_I({
    hps_io_gpio_inst_GPIO54[0:0] // 25:25
   ,hps_io_gpio_inst_GPIO53[0:0] // 24:24
   ,hps_io_gpio_inst_GPIO52[0:0] // 23:23
   ,hps_io_gpio_inst_GPIO51[0:0] // 22:22
   ,floating[1:0] // 21:20
   ,hps_io_gpio_inst_GPIO48[0:0] // 19:19
   ,floating[13:2] // 18:7
   ,hps_io_gpio_inst_GPIO35[0:0] // 6:6
   ,hps_io_gpio_inst_GPIO34[0:0] // 5:5
   ,floating[18:14] // 4:0
  })
,.LOANIO1_O({
    gpio_loanio_loanio1_o[28:0] // 28:0
  })
,.LOANIO0_OE({
    gpio_loanio_loanio0_oe[28:0] // 28:0
  })
,.LOANIO0_I({
    gpio_loanio_loanio0_i[28:0] // 28:0
  })
,.GPIO1_PORTA_OE({
    intermediate[41:41] // 25:25
   ,intermediate[39:39] // 24:24
   ,intermediate[37:37] // 23:23
   ,intermediate[35:35] // 22:22
   ,floating[20:19] // 21:20
   ,intermediate[33:33] // 19:19
   ,floating[32:21] // 18:7
   ,intermediate[31:31] // 6:6
   ,intermediate[29:29] // 5:5
   ,floating[37:33] // 4:0
  })
,.LOANIO2_O({
    gpio_loanio_loanio2_o[8:0] // 8:0
  })
,.LOANIO1_I({
    gpio_loanio_loanio1_i[28:0] // 28:0
  })
,.GPIO0_PORTA_O({
    intermediate[44:44] // 9:9
   ,floating[45:38] // 8:1
   ,intermediate[42:42] // 0:0
  })
,.LOANIO2_OE({
    gpio_loanio_loanio2_oe[8:0] // 8:0
  })
,.LOANIO2_I({
    gpio_loanio_loanio2_i[8:0] // 8:0
  })
,.GPIO0_PORTA_I({
    hps_io_gpio_inst_LOANIO09[0:0] // 9:9
   ,floating[53:46] // 8:1
   ,hps_io_gpio_inst_LOANIO00[0:0] // 0:0
  })
,.GPIO0_PORTA_OE({
    intermediate[45:45] // 9:9
   ,floating[61:54] // 8:1
   ,intermediate[43:43] // 0:0
  })
,.GPIO1_PORTA_O({
    intermediate[40:40] // 25:25
   ,intermediate[38:38] // 24:24
   ,intermediate[36:36] // 23:23
   ,intermediate[34:34] // 22:22
   ,floating[63:62] // 21:20
   ,intermediate[32:32] // 19:19
   ,floating[75:64] // 18:7
   ,intermediate[30:30] // 6:6
   ,intermediate[28:28] // 5:5
   ,floating[80:76] // 4:0
  })
,.LOANIO1_OE({
    gpio_loanio_loanio1_oe[28:0] // 28:0
  })
,.LOANIO0_O({
    gpio_loanio_loanio0_o[28:0] // 28:0
  })
);


hps_sdram hps_sdram_inst(
 .mem_dq({
    mem_dq[31:0] // 31:0
  })
,.mem_odt({
    mem_odt[0:0] // 0:0
  })
,.mem_ras_n({
    mem_ras_n[0:0] // 0:0
  })
,.mem_dqs_n({
    mem_dqs_n[3:0] // 3:0
  })
,.mem_dqs({
    mem_dqs[3:0] // 3:0
  })
,.mem_dm({
    mem_dm[3:0] // 3:0
  })
,.mem_we_n({
    mem_we_n[0:0] // 0:0
  })
,.mem_cas_n({
    mem_cas_n[0:0] // 0:0
  })
,.mem_ba({
    mem_ba[2:0] // 2:0
  })
,.mem_a({
    mem_a[14:0] // 14:0
  })
,.mem_cs_n({
    mem_cs_n[0:0] // 0:0
  })
,.mem_ck({
    mem_ck[0:0] // 0:0
  })
,.mem_cke({
    mem_cke[0:0] // 0:0
  })
,.oct_rzqin({
    oct_rzqin[0:0] // 0:0
  })
,.mem_reset_n({
    mem_reset_n[0:0] // 0:0
  })
,.mem_ck_n({
    mem_ck_n[0:0] // 0:0
  })
);

endmodule

