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


// $Id: //acds/rel/18.1std/ip/sld/st/altera_mm_debug_link_datawidth_matcher/altera_mm_debug_link_datawidth_matcher.sv#1 $
// $Revision: #1 $
// $Date: 2018/07/18 $
// $Author: psgswbuild $

///////////////////////////
// Altera MM-Debug-Link Datawidth-matcher
//
// This component adapts between a sink and source with differing data widths.
// There are two expected use cases:
// 1) Sink datawidth > source datawidth
//    The upper bits of the sink data are discarded; the (source datawidth)
//    lsbs of the sink data are passed through to the source.
// 2) Sink datawidth < source datawidth
//    The (sink datawidth) lsbs of the source data are driven from the sink
//    data.  The remaining bits of the sink data are driven with X.
// If sink and source datawidth are equal, all data is passed through.
//
// Note: ST is big-endian, and this is taken into account in the assignments.
// That is: for an 8-to-32-bit matcher, the 8 bits of input map to bits 31:24
// of the output.  
//
// This component has only been used in 8-to-32 and 32-to-8 bit forms, and the
// hw.tcl restricts to those values (except for the silly 8-to-8 and 32-to-32
// cases).
//
// There is no latency and no modification of data within this component (all
// assignments are combinational).  The unused clk and reset signals are
// provided to satisfy ST interface requirements.
//
// This component is used to allow a connection between mismatched datawidth
// ST interfaces where the extra data is unneeded, and where Qsys' attempts 
// to adapt are unnecessary.
//
///////////////////////////

`default_nettype none
`timescale 1 ns / 1 ns
module altera_mm_debug_link_datawidth_matcher #(
  parameter 
      SINK_DATAWIDTH = 8,
    SOURCE_DATAWIDTH = 32
  )
  (
    // ST-sink
    input wire [SINK_DATAWIDTH - 1:0] sink_data,
    input wire sink_valid,
    output wire sink_ready,

    // ST-source
    output wire [SOURCE_DATAWIDTH - 1:0] source_data,
    output wire source_valid,
    input wire source_ready,

    // clk sink
    input wire clk,

    // reset sink
    input wire reset
  );

  // Straight-through ready, valid assignments
  assign sink_ready = source_ready;
  assign source_valid = sink_valid;

  generate
    if (SINK_DATAWIDTH > SOURCE_DATAWIDTH) begin
      assign source_data = sink_data[SINK_DATAWIDTH-1: SINK_DATAWIDTH - SOURCE_DATAWIDTH];
    end
    else if (SINK_DATAWIDTH < SOURCE_DATAWIDTH) begin
      assign source_data =
        {sink_data, {SOURCE_DATAWIDTH - SINK_DATAWIDTH {1'bX}}};
    end
    else begin
      // Equal datawidths - not sure why one would do this, but it's here for
      // completeness.
      assign source_data = sink_data;
    end
  endgenerate

endmodule
`default_nettype wire

