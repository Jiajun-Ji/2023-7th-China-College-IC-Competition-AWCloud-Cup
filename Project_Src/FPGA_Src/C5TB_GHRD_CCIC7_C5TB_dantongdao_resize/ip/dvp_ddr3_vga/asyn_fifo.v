// *********************************************************************
// 
// Copyright (C) 2021-20xx CrazyBird Corporation
// 
// Filename     :   asyn_fifo.v
// Author       :   CrazyBird
// Email        :   CrazyBirdLin@qq.com
// 
// Description  :   
// 
// Modification History
// Date         By          Version         Change Description
//----------------------------------------------------------------------
// 2022/03/20   asyn_fifo   1.0             Original
// 
// *********************************************************************
module asyn_fifo 
#( 
    parameter C_DATA_WIDTH       = 8,
    parameter C_FIFO_DEPTH_WIDTH = 4
)( 
    input  wire                         wr_rst_n    ,
    input  wire                         wr_clk      ,
    input  wire                         wr_en       ,
    input  wire [C_DATA_WIDTH-1:0]      wr_data     ,
    output wire                         wr_full     ,
    output reg  [C_FIFO_DEPTH_WIDTH:0]  wr_cnt      ,
    input  wire                         rd_rst_n    ,
    input  wire                         rd_clk      ,
    input  wire                         rd_en       ,
    output wire [C_DATA_WIDTH-1:0]      rd_data     ,
    output wire                         rd_empty    ,
    output reg  [C_FIFO_DEPTH_WIDTH:0]  rd_cnt      
); 
//----------------------------------------------------------------------
//  内部变量定义
reg     [C_DATA_WIDTH-1:0]      mem     [0:(1 << C_FIFO_DEPTH_WIDTH)-1];
wire    [C_FIFO_DEPTH_WIDTH-1:0]        wr_addr;
wire    [C_FIFO_DEPTH_WIDTH-1:0]        rd_addr;
reg     [C_FIFO_DEPTH_WIDTH:0]          wr_addr_ptr;
reg     [C_FIFO_DEPTH_WIDTH:0]          rd_addr_ptr; 
wire    [C_FIFO_DEPTH_WIDTH:0]          wr_addr_gray;
reg     [C_FIFO_DEPTH_WIDTH:0]          wr_addr_gray_d1; 
reg     [C_FIFO_DEPTH_WIDTH:0]          wr_addr_gray_d2;
wire    [C_FIFO_DEPTH_WIDTH:0]          wr_addr_bin; 
wire    [C_FIFO_DEPTH_WIDTH:0]          rd_addr_gray; 
reg     [C_FIFO_DEPTH_WIDTH:0]          rd_addr_gray_d1;
reg     [C_FIFO_DEPTH_WIDTH:0]          rd_addr_gray_d2;
wire    [C_FIFO_DEPTH_WIDTH:0]          rd_addr_bin;
wire    [C_FIFO_DEPTH_WIDTH-1:0]        rd_cnt_w;
wire    [C_FIFO_DEPTH_WIDTH-1:0]        wr_cnt_w;

//----------------------------------------------------------------------
//  双端口RAM的读写
//  写RAM
always @(posedge wr_clk)
begin 
    if(wr_en && (~wr_full)) 
        mem[wr_addr] <= wr_data; 
    else 
        mem[wr_addr] <= mem[wr_addr]; 
end 

//  读RAM
assign rd_data = mem[rd_addr];

//----------------------------------------------------------------------
//  RAM读写地址
assign wr_addr = wr_addr_ptr[C_FIFO_DEPTH_WIDTH-1:0]; 
assign rd_addr = rd_addr_ptr[C_FIFO_DEPTH_WIDTH-1:0]; 

//----------------------------------------------------------------------
//  二进制读写指针的产生
always @(posedge wr_clk or negedge wr_rst_n)
begin 
    if(wr_rst_n == 1'b0) 
        wr_addr_ptr <= {(C_FIFO_DEPTH_WIDTH+1){1'b0}}; 
    else if(wr_en && (~wr_full)) 
        wr_addr_ptr <= wr_addr_ptr + 1; 
    else 
        wr_addr_ptr <= wr_addr_ptr; 
end 

always @(posedge rd_clk or negedge rd_rst_n)
begin 
    if(rd_rst_n == 1'b0) 
        rd_addr_ptr <= {(C_FIFO_DEPTH_WIDTH+1){1'b0}}; 
    else if(rd_en && (~rd_empty)) 
        rd_addr_ptr <= rd_addr_ptr + 1; 
    else 
        rd_addr_ptr <= rd_addr_ptr; 
end 

//----------------------------------------------------------------------
//  二进制转格雷码
assign wr_addr_gray = (wr_addr_ptr >> 1) ^ wr_addr_ptr; 
assign rd_addr_gray = (rd_addr_ptr >> 1) ^ rd_addr_ptr;

//----------------------------------------------------------------------
//  格雷码转二进制
genvar                          i;

generate
    for(i = 0;i < C_FIFO_DEPTH_WIDTH + 1;i = i+1)
    begin : wr_gray_to_bin
        assign wr_addr_bin[i] = ^(wr_addr_gray_d2 >> i);
    end
endgenerate

generate
    for(i = 0;i < C_FIFO_DEPTH_WIDTH + 1;i = i+1)
    begin : rd_gray_to_bin
        assign rd_addr_bin[i] = ^(rd_addr_gray_d2 >> i);
    end
endgenerate

//----------------------------------------------------------------------
//  两级寄存器同步
always @(posedge rd_clk) 
begin 
    wr_addr_gray_d1 <= wr_addr_gray; 
    wr_addr_gray_d2 <= wr_addr_gray_d1; 
end 

always @(posedge wr_clk) 
begin 
    rd_addr_gray_d1 <= rd_addr_gray; 
    rd_addr_gray_d2 <= rd_addr_gray_d1; 
end 

//----------------------------------------------------------------------
//  FIFO空满标志位的产生和读写FIFO数据量的计数
assign wr_full = (wr_addr_gray == {~(rd_addr_gray_d2[C_FIFO_DEPTH_WIDTH:C_FIFO_DEPTH_WIDTH-1]),
                  rd_addr_gray_d2[C_FIFO_DEPTH_WIDTH-2:0]});
assign rd_empty = (rd_addr_gray == wr_addr_gray_d2); 

assign wr_cnt_w = wr_addr_ptr - rd_addr_bin;
assign rd_cnt_w = wr_addr_bin - rd_addr_ptr;

always @(posedge wr_clk or negedge wr_rst_n)
begin
    if(wr_rst_n == 1'b0)
        wr_cnt <= {(C_FIFO_DEPTH_WIDTH+1){1'b0}};
    else
        wr_cnt <= wr_cnt_w;
end

always @(posedge rd_clk or negedge rd_rst_n)
begin
    if(rd_rst_n == 1'b0)
        rd_cnt <= {(C_FIFO_DEPTH_WIDTH+1){1'b0}};
    else
        rd_cnt <= rd_cnt_w;
end

endmodule