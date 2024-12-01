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


// $Id: //acds/rel/18.1std/ip/sld/mm/altera_mm_mgmt_wrapper/altera_mm_mgmt_wrapper.sv#1 $
// $Revision: #1 $
// $Date: 2018/07/18 $

`default_nettype none
`timescale 1 ns / 1 ns

module altera_mm_mgmt_wrapper #(
    parameter CHANNEL_WIDTH = 8
) (
  input  wire        clk,
  input  wire        reset,
  input  wire [1:0]  csr_address,
  input  wire        csr_write,
  input  wire        csr_read,
  output reg [31:0] csr_readdata,
  input  wire [31:0] csr_writedata,
  output reg    mgmt_valid,
  output reg    mgmt_data,
  output reg [CHANNEL_WIDTH-1:0] mgmt_channel,

  output reg debug_reset
);

  localparam 
    VERSION   = 32'h1,
    // SIGNATURE = 32'h53797343;
    SIGNATURE = "SysC";

  // Handle csr interfaces writes.
  // Write address map:
  //  offset    description
  //       0    reserved (do nothing)
  //       1    reserved (do nothing)
  //       2    csr_writedata[0] ? assert debug_reset : deassert debug_reset
  //       3    mgmt_data = csr_writedata[0]
  //            mgmt_channel = csr_writedata[8 +: CHANNEL_WIDTH]

  // mgmt
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      mgmt_valid   <= '0;
      mgmt_data    <= '0;
      mgmt_channel <= '0;
    end
    else begin
      mgmt_data    <= csr_writedata[0];
      mgmt_channel <= csr_writedata[8 +: CHANNEL_WIDTH];
      mgmt_valid   <= csr_write & (csr_address == 2'd3);
    end
  end

  // debug_reset
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      debug_reset <= '1;
    end
    else if (csr_write & (csr_address == 2'd2)) begin
      debug_reset <= csr_writedata[0];
    end
  end

  // csr readdata
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      csr_readdata <= '0;
    end
    else begin
      csr_readdata <= (csr_address == 2'd0) ? SIGNATURE :
                      (csr_address == 2'd1) ? VERSION :
                      32'hx;
    end
  end

endmodule
`default_nettype wire

