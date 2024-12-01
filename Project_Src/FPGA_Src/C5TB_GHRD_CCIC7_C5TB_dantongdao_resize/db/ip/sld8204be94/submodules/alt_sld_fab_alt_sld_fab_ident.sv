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


// $Id: //acds/main/ip/altera_connection_identification_hub/altera_connection_identification_hub.sv.terp#1 $
// $Revision: #1 $
// $Date: 2012/05/24 $
// $Author: adraper $

// -------------------------------------------------------
// Altera Identification hub
//
// Parameters
//   DESIGN_HASH   : 4552d32562c88dcb4ade
//   COUNT         : 3
//   ROM_WIDTHS    : 4 32 4
//   LATENCIES     : 0 0 0
//
// -------------------------------------------------------


`timescale 1 ns / 1 ns

module alt_sld_fab_alt_sld_fab_ident
(
	input [4:0] address_0,
	input [3:0] contrib_0,
	output [3:0] rdata_0,
	input [1:0] address_1,
	input [3:0] contrib_1,
	output [31:0] rdata_1,
	input [4:0] address_2,
	input [3:0] contrib_2,
	output [3:0] rdata_2,
	output [3:0] mixed
);


wire [127:0] data_0 = { mixed, 12'h0, 32'h0, 80'h4552d32562c88dcb4ade };

reg [3:0] result_0;
always @(address_0 or data_0) begin
        case (address_0)
            0: result_0 <= data_0[0+:4];    
            1: result_0 <= data_0[4+:4];    
            2: result_0 <= data_0[8+:4];    
            3: result_0 <= data_0[12+:4];    
            4: result_0 <= data_0[16+:4];    
            5: result_0 <= data_0[20+:4];    
            6: result_0 <= data_0[24+:4];    
            7: result_0 <= data_0[28+:4];    
            8: result_0 <= data_0[32+:4];    
            9: result_0 <= data_0[36+:4];    
            10: result_0 <= data_0[40+:4];    
            11: result_0 <= data_0[44+:4];    
            12: result_0 <= data_0[48+:4];    
            13: result_0 <= data_0[52+:4];    
            14: result_0 <= data_0[56+:4];    
            15: result_0 <= data_0[60+:4];    
            16: result_0 <= data_0[64+:4];    
            17: result_0 <= data_0[68+:4];    
            18: result_0 <= data_0[72+:4];    
            19: result_0 <= data_0[76+:4];    
            20: result_0 <= data_0[80+:4];    
            21: result_0 <= data_0[84+:4];    
            22: result_0 <= data_0[88+:4];    
            23: result_0 <= data_0[92+:4];    
            24: result_0 <= data_0[96+:4];    
            25: result_0 <= data_0[100+:4];    
            26: result_0 <= data_0[104+:4];    
            27: result_0 <= data_0[108+:4];    
            28: result_0 <= data_0[112+:4];    
            29: result_0 <= data_0[116+:4];    
            30: result_0 <= data_0[120+:4];    
            31: result_0 <= data_0[124+:4];    
            default: result_0 <= 0;
        endcase
end
assign rdata_0 = result_0;


wire [127:0] data_1 = { mixed, 12'h1, 32'h0, 80'h4552d32562c88dcb4ade };

reg [31:0] result_1;
always @(address_1 or data_1) begin
        case (address_1)
            0: result_1 <= data_1[0+:32];    
            1: result_1 <= data_1[32+:32];    
            2: result_1 <= data_1[64+:32];    
            3: result_1 <= data_1[96+:32];    
            default: result_1 <= 0;
        endcase
end
assign rdata_1 = result_1;


wire [127:0] data_2 = { mixed, 12'h2, 32'h0, 80'h4552d32562c88dcb4ade };

reg [3:0] result_2;
always @(address_2 or data_2) begin
        case (address_2)
            0: result_2 <= data_2[0+:4];    
            1: result_2 <= data_2[4+:4];    
            2: result_2 <= data_2[8+:4];    
            3: result_2 <= data_2[12+:4];    
            4: result_2 <= data_2[16+:4];    
            5: result_2 <= data_2[20+:4];    
            6: result_2 <= data_2[24+:4];    
            7: result_2 <= data_2[28+:4];    
            8: result_2 <= data_2[32+:4];    
            9: result_2 <= data_2[36+:4];    
            10: result_2 <= data_2[40+:4];    
            11: result_2 <= data_2[44+:4];    
            12: result_2 <= data_2[48+:4];    
            13: result_2 <= data_2[52+:4];    
            14: result_2 <= data_2[56+:4];    
            15: result_2 <= data_2[60+:4];    
            16: result_2 <= data_2[64+:4];    
            17: result_2 <= data_2[68+:4];    
            18: result_2 <= data_2[72+:4];    
            19: result_2 <= data_2[76+:4];    
            20: result_2 <= data_2[80+:4];    
            21: result_2 <= data_2[84+:4];    
            22: result_2 <= data_2[88+:4];    
            23: result_2 <= data_2[92+:4];    
            24: result_2 <= data_2[96+:4];    
            25: result_2 <= data_2[100+:4];    
            26: result_2 <= data_2[104+:4];    
            27: result_2 <= data_2[108+:4];    
            28: result_2 <= data_2[112+:4];    
            29: result_2 <= data_2[116+:4];    
            30: result_2 <= data_2[120+:4];    
            31: result_2 <= data_2[124+:4];    
            default: result_2 <= 0;
        endcase
end
assign rdata_2 = result_2;

// TODO: Cut timing paths into and out of mixed

assign mixed =
	contrib_0 ^
	contrib_1 ^
	contrib_2 ^
	4'h0;

endmodule

