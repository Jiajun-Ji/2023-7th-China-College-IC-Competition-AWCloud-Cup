module plot_ctrl(
	input clk,
	input reset_n,
	//slave����
	input chipselect,
	input [3:0]as_address,
	input as_write,
	input [31:0]as_writedata,
	input as_read,
	output reg[31:0]as_readdata,
	//������־
    output   wire   [9:0]   num_rec  ,     //����
	//������
    output   wire   [9:0]   zuoshang_x  ,   //���Ͽ�x
    output   wire   [9:0]   zuoshang_y  ,   //���Ͽ�y
    output   wire   [9:0]   youxia_x    ,   //���¿�x
    output   wire   [9:0]   youxia_y    ,   //���¿�y
	//���ǩ
	output    wire  [2:0]   label		,
	//�����Ŷ�
	output    wire  [13:0]  acc			,
	//���崫���־λ
	output    wire 			all_rec     ,
	//���������־λ
	output    wire 			single_rec
);
//������־
reg   [9:0]   num_rec_reg  ;     //����
//������
reg   [9:0]   zuoshang_x_reg  ;   //���Ͽ�x
reg   [9:0]   zuoshang_y_reg  ;   //���Ͽ�y
reg   [9:0]   youxia_x_reg    ;   //���¿�x
reg   [9:0]   youxia_y_reg    ;   //���¿�y
//���ǩ
reg  [2:0]      label_reg		;
//�����Ŷ�
reg  [13:0]     acc_reg			;
//���崫���־λ
reg 			all_rec_reg     ;
//���������־λ
reg 			single_rec_reg;
//��ֵ
assign num_rec    = num_rec_reg    ;    
assign zuoshang_x = zuoshang_x_reg ; 
assign zuoshang_y = zuoshang_y_reg ; 
assign youxia_x   = youxia_x_reg   ;  
assign youxia_y   = youxia_y_reg   ;  
assign label	  = label_reg 	   ;
assign acc		  = acc_reg 	   ;  
assign all_rec    = all_rec_reg    ; 
assign single_rec = single_rec_reg ;

//���崫��Ĵ���
always@(posedge clk or negedge reset_n)
	if(!reset_n)
		all_rec_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd0)
			all_rec_reg <= as_writedata[0];
		else 
			all_rec_reg <= all_rec_reg;
	end
	else 
		all_rec_reg <= all_rec_reg;

//��������Ĵ���
always@(posedge clk or negedge reset_n)
	if(!reset_n)
		single_rec_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd1)
			single_rec_reg <= as_writedata[0];
		else 
			single_rec_reg <= single_rec_reg;
	end
	else 
		single_rec_reg <= single_rec_reg;

//���������Ĵ���
always@(posedge clk or negedge reset_n)
	if(!reset_n)
		num_rec_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd2)
			num_rec_reg <= as_writedata[9:0];
		else 
			num_rec_reg <= num_rec_reg;
	end
	else 
		num_rec_reg <= num_rec_reg;

//������Ĵ���
always@(posedge clk or negedge reset_n)
	if(!reset_n)
		zuoshang_x_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd3)
			zuoshang_x_reg <= as_writedata[9:0];
		else 
			zuoshang_x_reg <= zuoshang_x_reg;
	end
	else 
		zuoshang_x_reg <= zuoshang_x_reg;

always@(posedge clk or negedge reset_n)
	if(!reset_n)
		zuoshang_y_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd4)
			zuoshang_y_reg <= as_writedata[9:0];
		else 
			zuoshang_y_reg <= zuoshang_y_reg;
	end
	else 
		zuoshang_y_reg <= zuoshang_y_reg;

always@(posedge clk or negedge reset_n)
	if(!reset_n)
		youxia_x_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd5)
			youxia_x_reg <= as_writedata[9:0];
		else 
			youxia_x_reg <= youxia_x_reg;
	end
	else 
		youxia_x_reg <= youxia_x_reg;

always@(posedge clk or negedge reset_n)
	if(!reset_n)
		youxia_y_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd6)
			youxia_y_reg <= as_writedata[9:0];
		else 
			youxia_y_reg <= youxia_y_reg;
	end
	else 
		youxia_y_reg <= youxia_y_reg;

//���ǩ�Ĵ���
always@(posedge clk or negedge reset_n)
	if(!reset_n)
		label_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd7)
			label_reg <= as_writedata[2:0];
		else 
			label_reg <= label_reg;
	end
	else 
		label_reg <= label_reg;

//���ŶȼĴ���
always@(posedge clk or negedge reset_n)
	if(!reset_n)
		acc_reg <= 0;
	else if(chipselect && as_write)begin
		if(as_address == 4'd8)
			acc_reg <= as_writedata[13:0];
		else 
			acc_reg <= acc_reg;
	end
	else 
		acc_reg <= acc_reg;

//���Ĵ���
always@(posedge clk or negedge reset_n)
if(!reset_n)
	as_readdata <= 32'd0;	//��λ����Ϊ���ֵ����ֹ���ⴥ���������𻵴洢��������
else if(chipselect && as_read)begin
	case(as_address)
		0:as_readdata <= all_rec;
		1:as_readdata <= single_rec;
		2:as_readdata <= num_rec;
		3:as_readdata <= zuoshang_x;
		4:as_readdata <= zuoshang_y;
		5:as_readdata <= youxia_x;
		6:as_readdata <= youxia_y;
		7:as_readdata <= label;
		8:as_readdata <= acc;
	endcase	
end

endmodule

