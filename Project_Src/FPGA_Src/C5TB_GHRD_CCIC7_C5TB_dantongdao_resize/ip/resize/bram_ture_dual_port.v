module bram_ture_dual_port
#(
    parameter C_ADDR_WIDTH  = 8,
    parameter C_DATA_WIDTH  = 8
)(
    input  wire                     clka    ,
    input  wire                     wea     ,
    input  wire [C_ADDR_WIDTH-1:0]  addra   ,
    input  wire [C_DATA_WIDTH-1:0]  dina    ,
    output reg  [C_DATA_WIDTH-1:0]  douta   ,
    input  wire                     clkb    ,
    input  wire                     web     ,
    input  wire [C_ADDR_WIDTH-1:0]  addrb   ,
    input  wire [C_DATA_WIDTH-1:0]  dinb    ,
    output reg  [C_DATA_WIDTH-1:0]  doutb   
);
//----------------------------------------------------------------------
localparam C_MEM_DEPTH = {C_ADDR_WIDTH{1'b1}};

reg     [C_DATA_WIDTH-1:0]      mem [C_MEM_DEPTH:0];
integer                         i;

initial
begin
    for(i = 0;i <= C_MEM_DEPTH;i = i+1)
        mem[i] = 0;
end 

always @(posedge clka)
begin
    if(wea == 1'b1)
        mem[addra] <= dina; 
    else
        douta <= mem[addra];
end

always @(posedge clkb)
begin
    if(web == 1'b1)
        mem[addrb] <= dinb; 
    else
        doutb <= mem[addrb];
end

endmodule
