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


module altera_mgmt_reset (
   input        clk,
   input        reset,
   input        mgmt_data,
   input        mgmt_valid,
   output       mgmt_ready,
   output  reg  agent_reset
   );

//reset (the input) forces agent_reset active (high) immediately
//system console strobes 1 (data & valid both 1) to enable reset
//or strobes 0 (data=0, valid=1) to hold agent in reset
//assume data and valid synchronous to clk

   always @(posedge clk or posedge reset) begin
      if      (reset)      agent_reset <= 1'b1;
      else if (mgmt_valid) agent_reset <= ~mgmt_data;
   end 

assign mgmt_ready = 1'b1;

endmodule
