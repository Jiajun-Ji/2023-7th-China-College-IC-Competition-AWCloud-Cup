module  flag_generate
(
    input   wire            clk    		,   //输入工作时钟,频率5MHz
    input   wire            sys_rst_n   ,   //输入复位信号,低电平有效
	//vga当前坐标输入
    input   wire    [9:0]   pix_x  ,   //当前x像素坐标
    input   wire    [9:0]   pix_y  ,   //当前y像素坐标	
	//框坐标输入
    input   wire    [9:0]   zuoshang_x  ,   //左上框x
    input   wire    [9:0]   zuoshang_y  ,   //左上框y
    input   wire    [9:0]   youxia_x    ,   //右下框x
    input   wire    [9:0]   youxia_y    ,   //右下框y
	//标签输入
    input   wire    [2:0]   label    	,   //输入工作时钟,频率5MHz
	//置信度输入
    input   wire    [13:0]  acc    	,   //置信度
	//启动bin2bcd的标志位
	input    wire 			start	,
	//标志位输出
    output  wire            flag     //输出flag
);

parameter   ca_shang_W  =   10'd64 ,    //字符宽度
            ca_shang_H  =   10'd16  ;   //字符高度
parameter   zhen_kong_W =   10'd72 ,    //字符宽度
            zhen_kong_H =   10'd16  ;   //字符高度
parameter   zhe_zhou_W  =   10'd64 ,    //字符宽度
            zhe_zhou_H  =   10'd16  ;   //字符高度
parameter   zang_wu_W   =   10'd56 ,    //字符宽度
            zang_wu_H   =   10'd16  ;   //字符高度

//字模
reg     [63:0] ca_shang [15:0];    //字符数据
reg     [71:0] zhen_kong [15:0];   //字符数据
reg     [63:0] zhe_zhou [15:0];    //字符数据
reg     [55:0] zang_wu [15:0];    //字符数据

reg     [7:0] xiaoshudian [15:0];  //字符数据
reg     [7:0] zero [15:0];  //字符数据
reg     [7:0] one  [15:0];  //字符数据
reg     [7:0] two  [15:0];  //字符数据
reg     [7:0] three [15:0];  //字符数据
reg     [7:0] four  [15:0];  //字符数据
reg     [7:0] five  [15:0];  //字符数据
reg     [7:0] six [15:0];  //字符数据
reg     [7:0] seven  [15:0];  //字符数据
reg     [7:0] eight  [15:0];  //字符数据
reg     [7:0] nine  [15:0];  //字符数据



//得到当前标签对应的参数,实际上就是多路复用器
reg     [9:0]  lable_w;   //标签字模的宽
wire    [9:0]  label_h;   //标签字模的高

always @ (label) begin
	case(label)
	  3'b001    : lable_w = ca_shang_W;      // If sel=0, output is a
	  3'b010    : lable_w = zhen_kong_W;     // If sel=1, output is b
	  3'b011    : lable_w = zhe_zhou_W;      // If sel=2, output is c
	  3'b100    : lable_w = zang_wu_W;       // If sel=2, output is c
	  default  : lable_w = ca_shang_W;      // If sel is anything else, out is always 0
	endcase
end
assign label_h = ca_shang_H;//由于所有字符都是16高度因此不变高度
  
//矩形框
wire     flag1;   //是否输出矩形框的flag
assign flag1 =(((pix_x >= zuoshang_x) && (pix_x <= youxia_x))   //约束行显示区间
             && ((pix_y == zuoshang_y) || (pix_y == youxia_y))) //约束行显示区间在哪一行
             ||(((pix_y >= zuoshang_y) && (pix_y <= youxia_y))  //约束列显示区间
             && ((pix_x == zuoshang_x) || (pix_x == youxia_x))); //约束列显示区间在哪一列

//标签
wire    [9:0]   char_x2  ;   //字符显示X轴坐标
wire    [9:0]   char_y2  ;   //字符显示Y轴坐标
wire     flag2;   //是否输出标签的flag
assign  char_x2  =   (((pix_x >= zuoshang_x) && (pix_x < (zuoshang_x + lable_w)))
                    && ((pix_y >= youxia_y-16) && (pix_y < (youxia_y + label_h-16))))
                    ? (pix_x - zuoshang_x) : 10'h3FF;
assign  char_y2  =   (((pix_x >= zuoshang_x) && (pix_x < (zuoshang_x + lable_w)))
                    && ((pix_y >= youxia_y-16) && (pix_y < (youxia_y + label_h-16))))
                    ? (pix_y - youxia_y+16) : 10'h3FF;
assign flag2=((pix_x >= (zuoshang_x - 1'b1))&&(pix_x < (zuoshang_x + lable_w -1'b1))
              && ((pix_y >= youxia_y-16) && (pix_y < (youxia_y-16 + label_h)))
              &&  ((char_x2!=10'h3FF)&&(char_y2!=10'h3FF))) 
               ? (((label == 3'b001)&& (ca_shang[char_y2][lable_w - char_x2 -1'b1])) || 
				 ((label == 3'b010)&& (zhen_kong[char_y2][lable_w - char_x2 -1'b1])) || 
		         ((label == 3'b011)&& (zhe_zhou[char_y2][lable_w - char_x2 -1'b1])) || 
		         ((label == 3'b100)&& (zang_wu[char_y2][lable_w - char_x2 -1'b1]))) :1'b0;
				
/////////////////////////////////////////////////////		
//置信度                                           //
/////////////////////////////////////////////////////

parameter   CHAR_W  =   10'd8 ,   //字符宽度
            CHAR_H  =   10'd16  ; //字符高度
parameter   off_set_x  =  10'd8,   //定义置信度与标签之间的偏移
			off_set_y  =  10'd16;
parameter   off_set_char1  =  0*CHAR_W ,   //定义字符间的偏移
			off_set_char2  =  1*CHAR_W ,
			off_set_char3  =  2*CHAR_W ,
			off_set_char4  =  3*CHAR_W ,
			off_set_char5  =  4*CHAR_W ,
			off_set_char6  =  5*CHAR_W ;
			
wire    [9:0]   zifu_x1  ;   //第1个字符显示X轴坐标
wire    [9:0]   zifu_y1  ;   //第1个字符字符显示Y轴坐标
wire    [9:0]   zifu_x2  ;   //第2个字符显示X轴坐标
wire    [9:0]   zifu_y2  ;   //第2个字符字符显示Y轴坐标
wire    [9:0]   zifu_x3  ;   //第3个字符显示X轴坐标
wire    [9:0]   zifu_y3  ;   //第3个字符字符显示Y轴坐标
wire    [9:0]   zifu_x4  ;   //第4个字符显示X轴坐标
wire    [9:0]   zifu_y4  ;   //第4个字符字符显示Y轴坐标
wire    [9:0]   zifu_x5  ;   //第5个字符显示X轴坐标
wire    [9:0]   zifu_y5  ;   //第5个字符字符显示Y轴坐标
wire    [9:0]   zifu_x6  ;   //第6个字符显示X轴坐标
wire    [9:0]   zifu_y6  ;   //第6个字符字符显示Y轴坐标

wire     flag3;   //是否输出置信度像素的flag
wire     char1;   //置信度字符1flag
wire     char2;   //置信度字符2flag
wire     char3;   //置信度字符3flag
wire     char4;   //置信度字符4flag
wire     char5;   //置信度字符5flag
wire     char6;   //置信度字符6flag

wire    [9:0]   zifu_x1_start  ;   //第1个字符显示X轴坐标起始
wire    [9:0]   zifu_x1_end  ;     //第1个字符显示X轴坐标结束
wire    [9:0]   zifu_y1_start  ;   //第1个字符显示Y轴坐标起始
wire    [9:0]   zifu_y1_end  ;     //第1个字符显示Y轴坐标结束
wire    [9:0]   zifu_x2_start  ;   //第2个字符显示X轴坐标起始
wire    [9:0]   zifu_x2_end  ;     //第2个字符显示X轴坐标结束
wire    [9:0]   zifu_x3_start  ;   //第3个字符显示X轴坐标起始
wire    [9:0]   zifu_x3_end  ;     //第3个字符显示X轴坐标结束
wire    [9:0]   zifu_x4_start  ;   //第4个字符显示X轴坐标起始
wire    [9:0]   zifu_x4_end  ;     //第4个字符显示X轴坐标结束
wire    [9:0]   zifu_x5_start  ;   //第5个字符显示X轴坐标起始
wire    [9:0]   zifu_x5_end  ;     //第5个字符显示X轴坐标结束
wire    [9:0]   zifu_x6_start  ;   //第6个字符显示X轴坐标起始
wire    [9:0]   zifu_x6_end  ;     //第6个字符显示X轴坐标结束

wire     display_area1;
wire     display_area2;
wire     display_area3;
wire     display_area4;
wire     display_area5;
wire     display_area6;

reg     zifu1;   //置信度字符1
wire    zifu2;   //置信度字符2
reg     zifu3;   //置信度字符3
reg     zifu4;   //置信度字符4
reg     zifu5;   //置信度字符5
reg     zifu6;   //置信度字符6

//二进制转BCD码
reg [12:0] bin;
wire ready, done_tick;
wire [3:0] bcd3, bcd2, bcd1, bcd0;

bin2bcd u1_bin2bcd
(
    .clk(clk),
    .rst_n(sys_rst_n),
    .start(start),
    .bin(acc),
    .ready(ready),
    .done_tick(done_tick),
    .bcd4(bcd4),
    .bcd3(bcd3),
    .bcd2(bcd2),
    .bcd1(bcd1),
    .bcd0(bcd0)
);

//显示第一个字符
assign zifu_x1_start = zuoshang_x+ lable_w+off_set_x+ off_set_char1;
assign zifu_y1_start = youxia_y-off_set_y;
assign zifu_x1_end   = zifu_x1_start+ CHAR_W;
assign zifu_y1_end   = zifu_y1_start + CHAR_H;

assign display_area1 = (((pix_x >= zifu_x1_start) && (pix_x < (zifu_x1_end)))//计算第一个字符显示区域
                    && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end))));

assign  zifu_x1  = display_area1 ? (pix_x - zifu_x1_start) : 10'h3FF;//根据显示区域得到字模计数值
assign  zifu_y1  = display_area1 ? (pix_y - zifu_y1_start) : 10'h3FF;
							
//根据输入BCD码选择输出	
always @ (*) begin//根据bcd码选择字模
	case(bcd4)
	  4'd0    : zifu1 <= zero [zifu_y1][CHAR_W - zifu_x1 -1'b1];     
	  4'd1    : zifu1 <= one  [zifu_y1][CHAR_W - zifu_x1 -1'b1];    
	  4'd2    : zifu1 <= two  [zifu_y1][CHAR_W - zifu_x1 -1'b1];   
	  4'd3    : zifu1 <= three[zifu_y1][CHAR_W - zifu_x1 -1'b1];     
	  4'd4    : zifu1 <= four [zifu_y1][CHAR_W - zifu_x1 -1'b1];     
	  4'd5    : zifu1 <= five [zifu_y1][CHAR_W - zifu_x1 -1'b1];    
	  4'd6    : zifu1 <= six  [zifu_y1][CHAR_W - zifu_x1 -1'b1];   
	  4'd7    : zifu1 <= seven[zifu_y1][CHAR_W - zifu_x1 -1'b1];  
	  4'd8    : zifu1 <= eight[zifu_y1][CHAR_W - zifu_x1 -1'b1];   
	  4'd9    : zifu1 <= nine [zifu_y1][CHAR_W - zifu_x1 -1'b1]; 
	  default : zifu1 <= zero [zifu_y1][CHAR_W - zifu_x1 -1'b1];      
	endcase
end	
	
assign char1=((pix_x >= (zifu_x1_start - 1'b1))&&(pix_x < (zifu_x1_end - 1'b1))
              && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end)))
              &&  ((zifu_x1!=10'h3FF)&&(zifu_y1!=10'h3FF))) 
                ? zifu1:1'b0;

				
				
//显示第二个小数点字符		
assign zifu_x2_start = zuoshang_x + lable_w + off_set_x + off_set_char2;
assign zifu_x2_end   = zifu_x2_start+ CHAR_W;

assign display_area2 = (((pix_x >= zifu_x2_start) && (pix_x < (zifu_x2_end)))//计算第二个字符显示区域
                    && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end))));

assign  zifu_x2  = display_area2 ? (pix_x - zifu_x2_start) : 10'h3FF;//根据显示区域得到字模计数值
assign  zifu_y2  = display_area2 ? (pix_y - zifu_y1_start) : 10'h3FF;


assign zifu2=xiaoshudian[zifu_y2][CHAR_W - zifu_x2 -1'b1];

assign char2=((pix_x >= (zifu_x2_start - 1'b1))&&(pix_x < (zifu_x2_end - 1'b1))
              && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end)))
              &&  ((zifu_x2!=10'h3FF)&&(zifu_y2!=10'h3FF))) 
                ? zifu2:1'b0;		
	
//第三个字符
assign zifu_x3_start = zuoshang_x + lable_w + off_set_x + off_set_char3;
assign zifu_x3_end   = zifu_x3_start+ CHAR_W;

assign display_area3 = (((pix_x >= zifu_x3_start) && (pix_x < (zifu_x3_end)))//计算第三个字符显示区域
                    && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end))));

assign  zifu_x3  = display_area3 ? (pix_x - zifu_x3_start) : 10'h3FF;//根据显示区域得到字模计数值
assign  zifu_y3  = display_area3 ? (pix_y - zifu_y1_start) : 10'h3FF;
//根据输入BCD码选择输出	
always @ (*) begin//根据bcd码选择字模
	case(bcd3)
	  4'd0    : zifu3 <= zero [zifu_y3][CHAR_W - zifu_x3 -1'b1];     
	  4'd1    : zifu3 <= one  [zifu_y3][CHAR_W - zifu_x3 -1'b1];    
	  4'd2    : zifu3 <= two  [zifu_y3][CHAR_W - zifu_x3 -1'b1];   
	  4'd3    : zifu3 <= three[zifu_y3][CHAR_W - zifu_x3 -1'b1];     
	  4'd4    : zifu3 <= four [zifu_y3][CHAR_W - zifu_x3 -1'b1];     
	  4'd5    : zifu3 <= five [zifu_y3][CHAR_W - zifu_x3 -1'b1];    
	  4'd6    : zifu3 <= six  [zifu_y3][CHAR_W - zifu_x3 -1'b1];   
	  4'd7    : zifu3 <= seven[zifu_y3][CHAR_W - zifu_x3 -1'b1];  
	  4'd8    : zifu3 <= eight[zifu_y3][CHAR_W - zifu_x3 -1'b1];   
	  4'd9    : zifu3 <= nine [zifu_y3][CHAR_W - zifu_x3 -1'b1]; 
	  default : zifu3 <= zero [zifu_y3][CHAR_W - zifu_x3 -1'b1];      
	endcase
end		

assign char3=((pix_x >= (zifu_x3_start - 1'b1))&&(pix_x < (zifu_x3_end - 1'b1))
              && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end)))
              &&  ((zifu_x3!=10'h3FF)&&(zifu_y3!=10'h3FF))) 
                ? zifu3:1'b0;

//第四个字符	
assign zifu_x4_start = zuoshang_x + lable_w + off_set_x + off_set_char4;
assign zifu_x4_end   = zifu_x4_start+ CHAR_W;

assign display_area4 = (((pix_x >= zifu_x4_start) && (pix_x < (zifu_x4_end)))//计算第四个字符显示区域
                    && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end))));

assign  zifu_x4  = display_area4 ? (pix_x - zifu_x4_start) : 10'h3FF;//根据显示区域得到字模计数值
assign  zifu_y4  = display_area4 ? (pix_y - zifu_y1_start) : 10'h3FF;
//根据输入BCD码选择输出	
always @ (*) begin//根据bcd码选择字模
	case(bcd2)
	  4'd0    : zifu4 = zero [zifu_y4][CHAR_W - zifu_x4 -1'b1];     
	  4'd1    : zifu4 = one  [zifu_y4][CHAR_W - zifu_x4 -1'b1];    
	  4'd2    : zifu4 = two  [zifu_y4][CHAR_W - zifu_x4 -1'b1];   
	  4'd3    : zifu4 = three[zifu_y4][CHAR_W - zifu_x4 -1'b1];     
	  4'd4    : zifu4 = four [zifu_y4][CHAR_W - zifu_x4 -1'b1];     
	  4'd5    : zifu4 = five [zifu_y4][CHAR_W - zifu_x4 -1'b1];    
	  4'd6    : zifu4 = six  [zifu_y4][CHAR_W - zifu_x4 -1'b1];   
	  4'd7    : zifu4 = seven[zifu_y4][CHAR_W - zifu_x4 -1'b1];  
	  4'd8    : zifu4 = eight[zifu_y4][CHAR_W - zifu_x4 -1'b1];   
	  4'd9    : zifu4 = nine [zifu_y4][CHAR_W - zifu_x4 -1'b1]; 
	  default : zifu4 = zero [zifu_y4][CHAR_W - zifu_x4 -1'b1];      
	endcase
end		

assign char4=((pix_x >= (zifu_x4_start - 1'b1))&&(pix_x < (zifu_x4_end - 1'b1))
              && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end)))
              &&  ((zifu_x4!=10'h3FF)&&(zifu_y4!=10'h3FF))) 
                ? zifu4:1'b0;

//第五个字符
assign zifu_x5_start = zuoshang_x + lable_w + off_set_x + off_set_char5;
assign zifu_x5_end   = zifu_x5_start+ CHAR_W;

assign display_area5 = (((pix_x >= zifu_x5_start) && (pix_x < (zifu_x5_end)))//计算第五个字符显示区域
                    && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end))));

assign  zifu_x5  = display_area5 ? (pix_x - zifu_x5_start) : 10'h3FF;//根据显示区域得到字模计数值
assign  zifu_y5  = display_area5 ? (pix_y - zifu_y1_start) : 10'h3FF;
//根据输入BCD码选择输出	
always @ (*) begin//根据bcd码选择字模
	case(bcd1)
	  4'd0    : zifu5 = zero [zifu_y5][CHAR_W - zifu_x5 -1'b1];     
	  4'd1    : zifu5 = one  [zifu_y5][CHAR_W - zifu_x5 -1'b1];    
	  4'd2    : zifu5 = two  [zifu_y5][CHAR_W - zifu_x5 -1'b1];   
	  4'd3    : zifu5 = three[zifu_y5][CHAR_W - zifu_x5 -1'b1];     
	  4'd4    : zifu5 = four [zifu_y5][CHAR_W - zifu_x5 -1'b1];     
	  4'd5    : zifu5 = five [zifu_y5][CHAR_W - zifu_x5 -1'b1];    
	  4'd6    : zifu5 = six  [zifu_y5][CHAR_W - zifu_x5 -1'b1];   
	  4'd7    : zifu5 = seven[zifu_y5][CHAR_W - zifu_x5 -1'b1];  
	  4'd8    : zifu5 = eight[zifu_y5][CHAR_W - zifu_x5 -1'b1];   
	  4'd9    : zifu5 = nine [zifu_y5][CHAR_W - zifu_x5 -1'b1]; 
	  default : zifu5 = zero [zifu_y5][CHAR_W - zifu_x5 -1'b1];      
	endcase
end		

assign char5=((pix_x >= (zifu_x5_start - 1'b1))&&(pix_x < (zifu_x5_end - 1'b1))
              && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end)))
              &&  ((zifu_x5!=10'h3FF)&&(zifu_y5!=10'h3FF))) 
                ? zifu5:1'b0;
				
//第六个字符
assign zifu_x6_start = zuoshang_x + lable_w + off_set_x + off_set_char6;
assign zifu_x6_end   = zifu_x6_start+ CHAR_W;

assign display_area6 = (((pix_x >= zifu_x6_start) && (pix_x < (zifu_x6_end)))//计算第六个字符显示区域
                    && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end))));

assign  zifu_x6  = display_area6 ? (pix_x - zifu_x6_start) : 10'h3FF;//根据显示区域得到字模计数值
assign  zifu_y6  = display_area6 ? (pix_y - zifu_y1_start) : 10'h3FF;
//根据输入BCD码选择输出	
always @ (*) begin//根据bcd码选择字模
	case(bcd0)
	  4'd0    : zifu6 = zero [zifu_y6][CHAR_W - zifu_x6 -1'b1];     
	  4'd1    : zifu6 = one  [zifu_y6][CHAR_W - zifu_x6 -1'b1];    
	  4'd2    : zifu6 = two  [zifu_y6][CHAR_W - zifu_x6 -1'b1];   
	  4'd3    : zifu6 = three[zifu_y6][CHAR_W - zifu_x6 -1'b1];     
	  4'd4    : zifu6 = four [zifu_y6][CHAR_W - zifu_x6 -1'b1];     
	  4'd5    : zifu6 = five [zifu_y6][CHAR_W - zifu_x6 -1'b1];    
	  4'd6    : zifu6 = six  [zifu_y6][CHAR_W - zifu_x6 -1'b1];   
	  4'd7    : zifu6 = seven[zifu_y6][CHAR_W - zifu_x6 -1'b1];  
	  4'd8    : zifu6 = eight[zifu_y6][CHAR_W - zifu_x6 -1'b1];   
	  4'd9    : zifu6 = nine [zifu_y6][CHAR_W - zifu_x6 -1'b1]; 
	  default : zifu6 = zero [zifu_y6][CHAR_W - zifu_x6 -1'b1];      
	endcase
end		

assign char6=((pix_x >= (zifu_x6_start - 1'b1))&&(pix_x < (zifu_x6_end - 1'b1))
              && ((pix_y >= zifu_y1_start) && (pix_y < (zifu_y1_end)))
              &&  ((zifu_x6!=10'h3FF)&&(zifu_y6!=10'h3FF))) 
                ? zifu6:1'b0;	
				
//总输出			
assign flag3 = char1 || char2 || char3 || char4 || char5 || char6;//置信度输出
assign flag = flag1 || flag2 || flag3;//一整个框的输出

//=======================================================
//二维数组rom存储
//=======================================================
//zhen_kong
always@(posedge clk)
    begin
        zhen_kong[0]    <=  72'h000000000000000000;
        zhen_kong[1]    <=  72'h000000000000000000;
        zhen_kong[2]    <=  72'h000000000000000000;
        zhen_kong[3]    <=  72'h004000000040000000;
        zhen_kong[4]    <=  72'h004000000040000000;
        zhen_kong[5]    <=  72'h004000000040000000;
        zhen_kong[6]    <=  72'h004000000040000000;
        zhen_kong[7]    <=  72'h7E5E3C5E004C3C5E3E;
        zhen_kong[8]    <=  72'h0C6246620058466244;
        zhen_kong[9]    <=  72'h08427E420078424244;
        zhen_kong[10]   <=  72'h10424042006842423C;
        zhen_kong[11]   <=  72'h204242420044424240;
        zhen_kong[12]   <=  72'h60426642004666427C;
        zhen_kong[13]   <=  72'h7E421C420042184246;
        zhen_kong[14]   <=  72'h000000000000000042;
        zhen_kong[15]   <=  72'h00000000FF0000007C;
    end

//zhe_zhou
always@(posedge clk)
    begin
        zhe_zhou[0]    <=  64'h0000000000000000;
        zhe_zhou[1]    <=  64'h0000000000000000;
        zhe_zhou[2]    <=  64'h0000000000000000;
        zhe_zhou[3]    <=  64'h0040000000400000;
        zhe_zhou[4]    <=  64'h0040000000400000;
        zhe_zhou[5]    <=  64'h0040000000400000;
        zhe_zhou[6]    <=  64'h7E40000000400000;
        zhe_zhou[7]    <=  64'hFE5E3C007E5E3C42;
        zhe_zhou[8]    <=  64'h0E6246000C624642;
        zhe_zhou[9]    <=  64'h1C427E0008424242;
        zhe_zhou[10]   <=  64'h3842400010424242;
        zhe_zhou[11]   <=  64'h7042420020424246;
        zhe_zhou[12]   <=  64'hFF4266006042666E;
        zhe_zhou[13]   <=  64'hFF421C007E42183A;
        zhe_zhou[14]   <=  64'h0000000000000000;
        zhe_zhou[15]   <=  64'h000000FF00000000;
    end

//ca_shang
always@(posedge clk)
    begin
        ca_shang[0]    <=  64'h0000000000000000;
        ca_shang[1]    <=  64'h0000000000000000;
        ca_shang[2]    <=  64'h0000000000000000;
        ca_shang[3]    <=  64'h0000000040000000;
        ca_shang[4]    <=  64'h0000000040000000;
        ca_shang[5]    <=  64'h0000000040000000;
        ca_shang[6]    <=  64'h0000000040000000;
        ca_shang[7]    <=  64'h3C3C003C5E3C5E3E;
        ca_shang[8]    <=  64'h4646006662466244;
        ca_shang[9]    <=  64'h400E0060420E4244;
        ca_shang[10]   <=  64'h4076001C4276423C;
        ca_shang[11]   <=  64'h4246004242464240;
        ca_shang[12]   <=  64'h664E0066424E427C;
        ca_shang[13]   <=  64'h383A003C423A4246;
        ca_shang[14]   <=  64'h0000000000000042;
        ca_shang[15]   <=  64'h0000FF000000007C;
    end

//zang_wu
always@(posedge clk)
    begin
        zang_wu[0]    <=  56'h00000000000000;
        zang_wu[1]    <=  56'h00000000000000;
        zang_wu[2]    <=  56'h00000000000000;
        zang_wu[3]    <=  56'h00000000000000;
        zang_wu[4]    <=  56'h00000000000000;
        zang_wu[5]    <=  56'h00000000000000;
        zang_wu[6]    <=  56'h00000000000000;
        zang_wu[7]    <=  56'h7E3C5E3E00DB42;
        zang_wu[8]    <=  56'h0C46624400DA42;
        zang_wu[9]    <=  56'h080E4244005A42;
        zang_wu[10]   <=  56'h1076423C006A42;
        zang_wu[11]   <=  56'h20464240006646;
        zang_wu[12]   <=  56'h604E427C00646E;
        zang_wu[13]   <=  56'h7E3A424600243A;
        zang_wu[14]   <=  56'h00000042000000;
        zang_wu[15]   <=  56'h0000007CFF0000;
    end


//小数点
always@(posedge clk)
    begin
        xiaoshudian[0]    <=  8'h00;
        xiaoshudian[1]    <=  8'h00;
        xiaoshudian[2]    <=  8'h00;
        xiaoshudian[3]    <=  8'h00;
        xiaoshudian[4]    <=  8'h00;
        xiaoshudian[5]    <=  8'h00;
        xiaoshudian[6]    <=  8'h00;
        xiaoshudian[7]    <=  8'h00;
        xiaoshudian[8]    <=  8'h00;
        xiaoshudian[9]    <=  8'h00;
        xiaoshudian[10]   <=  8'h00;
        xiaoshudian[11]   <=  8'h00;
        xiaoshudian[12]   <=  8'hF0;
        xiaoshudian[13]   <=  8'h60;
        xiaoshudian[14]   <=  8'h00;
        xiaoshudian[15]   <=  8'h00;
    end

//0
always@(posedge clk)
    begin
        zero[0]    <=  8'h00;
        zero[1]    <=  8'h00;
        zero[2]    <=  8'h18;
        zero[3]    <=  8'h7E;
        zero[4]    <=  8'h7E;
        zero[5]    <=  8'hE7;
        zero[6]    <=  8'hE7;
        zero[7]    <=  8'hE7;
        zero[8]    <=  8'hE7;
        zero[9]    <=  8'hE7;
        zero[10]   <=  8'hE7;
        zero[11]   <=  8'hE7;
        zero[12]   <=  8'h7E;
        zero[13]   <=  8'h3C;
        zero[14]   <=  8'h00;
        zero[15]   <=  8'h00;
    end


//1
always@(posedge clk)
    begin
        one[0]    <=  8'h00;
        one[1]    <=  8'h00;
        one[2]    <=  8'h00;
        one[3]    <=  8'h1C;
        one[4]    <=  8'h3C;
        one[5]    <=  8'h7C;
        one[6]    <=  8'h7C;
        one[7]    <=  8'h1C;
        one[8]    <=  8'h1C;
        one[9]    <=  8'h1C;
        one[10]   <=  8'h1C;
        one[11]   <=  8'h1C;
        one[12]   <=  8'h1C;
        one[13]   <=  8'h1C;
        one[14]   <=  8'h00;
        one[15]   <=  8'h00;
    end

//2
always@(posedge clk)
    begin
        two[0]    <=  8'h00;
        two[1]    <=  8'h00;
        two[2]    <=  8'h18;
        two[3]    <=  8'h7E;
        two[4]    <=  8'hFE;
        two[5]    <=  8'hE7;
        two[6]    <=  8'h07;
        two[7]    <=  8'h0E;
        two[8]    <=  8'h0E;
        two[9]    <=  8'h1C;
        two[10]   <=  8'h38;
        two[11]   <=  8'h70;
        two[12]   <=  8'hFF;
        two[13]   <=  8'hFF;
        two[14]   <=  8'h00;
        two[15]   <=  8'h00;
    end


//3
always@(posedge clk)
    begin
        three[0]    <=  8'h00;
        three[1]    <=  8'h00;
        three[2]    <=  8'h18;
        three[3]    <=  8'h7E;
        three[4]    <=  8'hFF;
        three[5]    <=  8'hE7;
        three[6]    <=  8'h06;
        three[7]    <=  8'h1E;
        three[8]    <=  8'h1E;
        three[9]    <=  8'h07;
        three[10]   <=  8'h47;
        three[11]   <=  8'hE7;
        three[12]   <=  8'h7E;
        three[13]   <=  8'h7C;
        three[14]   <=  8'h00;
        three[15]   <=  8'h00;
    end

//4
always@(posedge clk)
    begin
        four[0]    <=  8'h00;
        four[1]    <=  8'h00;
        four[2]    <=  8'h04;
        four[3]    <=  8'h0E;
        four[4]    <=  8'h1E;
        four[5]    <=  8'h1E;
        four[6]    <=  8'h3E;
        four[7]    <=  8'h7E;
        four[8]    <=  8'h6E;
        four[9]    <=  8'hEE;
        four[10]   <=  8'hFF;
        four[11]   <=  8'hFF;
        four[12]   <=  8'h0E;
        four[13]   <=  8'h0E;
        four[14]   <=  8'h00;
        four[15]   <=  8'h00;
    end

//5
always@(posedge clk)
    begin
        five[0]    <=  8'h00;
        five[1]    <=  8'h00;
        five[2]    <=  8'h00;
        five[3]    <=  8'h7E;
        five[4]    <=  8'h7E;
        five[5]    <=  8'hE0;
        five[6]    <=  8'hFC;
        five[7]    <=  8'hFE;
        five[8]    <=  8'hC7;
        five[9]    <=  8'h07;
        five[10]   <=  8'h47;
        five[11]   <=  8'hC7;
        five[12]   <=  8'hFE;
        five[13]   <=  8'h7C;
        five[14]   <=  8'h00;
        five[15]   <=  8'h00;
    end

//6
always@(posedge clk)
    begin
        six[0]    <=  8'h00;
        six[1]    <=  8'h00;
        six[2]    <=  8'h0C;
        six[3]    <=  8'h1C;
        six[4]    <=  8'h1C;
        six[5]    <=  8'h38;
        six[6]    <=  8'h78;
        six[7]    <=  8'h7E;
        six[8]    <=  8'hE7;
        six[9]    <=  8'hE7;
        six[10]   <=  8'hE7;
        six[11]   <=  8'hE7;
        six[12]   <=  8'hFF;
        six[13]   <=  8'h7E;
        six[14]   <=  8'h00;
        six[15]   <=  8'h00;
    end

//7
always@(posedge clk)
    begin
        seven[0]    <=  8'h00;
        seven[1]    <=  8'h00;
        seven[2]    <=  8'h00;
        seven[3]    <=  8'hFF;
        seven[4]    <=  8'h7F;
        seven[5]    <=  8'h06;
        seven[6]    <=  8'h0E;
        seven[7]    <=  8'h0C;
        seven[8]    <=  8'h1C;
        seven[9]    <=  8'h18;
        seven[10]   <=  8'h38;
        seven[11]   <=  8'h38;
        seven[12]   <=  8'h38;
        seven[13]   <=  8'h70;
        seven[14]   <=  8'h00;
        seven[15]   <=  8'h00;
    end

//8
always@(posedge clk)
    begin
        eight[0]    <=  8'h00;
        eight[1]    <=  8'h00;
        eight[2]    <=  8'h10;
        eight[3]    <=  8'h7E;
        eight[4]    <=  8'hEE;
        eight[5]    <=  8'hE7;
        eight[6]    <=  8'hE6;
        eight[7]    <=  8'h7E;
        eight[8]    <=  8'hFE;
        eight[9]    <=  8'hE7;
        eight[10]   <=  8'hC7;
        eight[11]   <=  8'hE7;
        eight[12]   <=  8'hFE;
        eight[13]   <=  8'h7E;
        eight[14]   <=  8'h00;
        eight[15]   <=  8'h00;
    end

//9
always@(posedge clk)
    begin
        nine[0]    <=  8'h00;
        nine[1]    <=  8'h00;
        nine[2]    <=  8'h18;
        nine[3]    <=  8'h7E;
        nine[4]    <=  8'hEE;
        nine[5]    <=  8'hE7;
        nine[6]    <=  8'hC7;
        nine[7]    <=  8'hE7;
        nine[8]    <=  8'hFE;
        nine[9]    <=  8'h7E;
        nine[10]   <=  8'h1C;
        nine[11]   <=  8'h18;
        nine[12]   <=  8'h38;
        nine[13]   <=  8'h70;
        nine[14]   <=  8'h00;
        nine[15]   <=  8'h00;
    end	



endmodule