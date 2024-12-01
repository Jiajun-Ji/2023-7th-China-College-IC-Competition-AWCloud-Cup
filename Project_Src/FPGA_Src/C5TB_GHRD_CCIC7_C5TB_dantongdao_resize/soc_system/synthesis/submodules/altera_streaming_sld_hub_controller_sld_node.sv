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


// $Id: //acds/rel/18.1std/ip/sld/st/altera_streaming_sld_hub_controller/altera_streaming_sld_hub_controller_sld_node.sv#1 $
// $Revision: #1 $
// $Date: 2018/07/18 $
// $Author: psgswbuild $
`default_nettype none

module altera_streaming_sld_hub_controller_sld_node #(
    parameter ENABLE_JTAG_IO_SELECTION = 0
  )
  (
    input wire  tck,
    input wire  tms,
    input wire  tdi,
    input wire  select_me,
    output wire tdo
  );

// synthesis read_comments_as_HDL on
//   altera_sld_host_endpoint #(
//     .ENABLE_JTAG_IO_SELECTION (ENABLE_JTAG_IO_SELECTION),
//     .CONTROL("hubctrl"),
//     .NAME("sldhub"),
//     .HOST_PRIORITY (200)
//   ) jtag_access (
//     .tck (tck),
//     .tms (tms),
//     .tdi (tdi),
//     .select_this (select_me),
//     .tdo (tdo)
//   );
// synthesis read_comments_as_HDL off

endmodule

`default_nettype wire

