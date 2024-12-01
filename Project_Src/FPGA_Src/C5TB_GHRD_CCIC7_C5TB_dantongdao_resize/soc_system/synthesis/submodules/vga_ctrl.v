module  vga_ctrl
#(
//����
	parameter USER_DATA_WIDTH = 128		//����λ��
)
(
    input   wire            clk    		,   //���빤��ʱ��,Ƶ��5MHz
    input   wire            sys_rst_n   ,   //���븴λ�ź�,�͵�ƽ��Ч
	//vgaʱ�����
    output  wire           	vga_clk     ,   //���vgaʱ��,Ƶ��5MHz
    output   wire           vga_de    	,   //��Ч����ѡͨ�ź�DE
    output  wire            vga_hsync   ,   //�����ͬ���ź�
    output  wire            vga_vsync   ,   //�����ͬ���ź�
    output  wire    [23:0]  vga_rgb     ,   //���24bit������Ϣ
	//������
	output  wire            read_req	,   			//���������ź�
	input   wire    [USER_DATA_WIDTH-1:0]  read_data,   	//������
	// ��ͬ����ʼ�볡ͬ��������־
    output  wire            cmos_vsync_begin,   //��ͬ����ʼ
    output  wire            cmos_vsync_end,     //��ͬ������
	//�������ź�
	//������־
    input   wire   [9:0]   num_rec  ,     //����
	//������
    input   wire   [9:0]   zuoshang_x  ,   //���Ͽ�x
    input   wire   [9:0]   zuoshang_y  ,   //���Ͽ�y
    input   wire   [9:0]   youxia_x    ,   //���¿�x
    input   wire   [9:0]   youxia_y    ,   //���¿�y
	//���ǩ
	input    wire  [2:0]   label		,
	//���崫���־λ
	input    wire 			all_rec     ,
	//���������־λ
	input    wire 			single_rec	,
	//�����Ŷ�
	input    wire  [13:0]  acc			
);

//=======================================================
//��������5Mʱ��35֡
//=======================================================

parameter H_SYNC    =    10'd15  ,   //��ͬ��    
          H_BACK    =    10'd0   ,   //��ʱ�����
          H_VALID   =    10'd400 ,   //����Ч����
          H_FRONT   =    10'd0   ,   //��ʱ��ǰ��
          H_TOTAL   =    10'd415 ;   //��ɨ������
parameter V_SYNC    =  10'd14   ,   //��ͬ��     
          V_BACK    =  10'd10  ,   //��ʱ�����  
          V_VALID   =  10'd320 ,   //����Ч����  
          V_FRONT   =  10'd0   ,   //��ʱ��ǰ��  
          V_TOTAL   =  10'd344 ;   //��ɨ������   

//=======================================================
//�źŶ���
//=======================================================

//ͬ���źŲ���
reg     [9:0]   cnt_h           ;   //��ͬ���źż�����
reg     [9:0]   cnt_v           ;   //��ͬ���źż�����

//���ݲ���
reg    [USER_DATA_WIDTH-1:0]  data_reg1;   	//�ݴ�3��read_data
reg    [USER_DATA_WIDTH-1:0]  data_reg;   	//��λ���vga_rgb
reg    [7:0]  					data;   		//�Ĵ�vga_rgb
reg	   [7:0]                 	cnt;            //����ʱ�������ش���
reg            				    read_req1;	   //���������źŴ�һ��
reg            				    read_req2;	   //���������źŴ�һ��
wire            				pix_data_req;	   //���������źŴ�һ��
wire            				pix_data_req1;	   //���������źŴ�һ��

reg                             vga_vsync_dly;  //vga�����ͬ���źŴ���
//���ؼ��
reg [1:0]D;				//���ؼ��Ĵ���
wire neg_edge;			//��׽read_req1�ź��½���
wire vga_de1;   //��Ч�źſ�ʼ
//=======================================================
//vgaͬ���źŲ���
//=======================================================

//vga_vsync_dly:vga�����ͬ���źŴ���,���ڲ���cmos_vsync_begin
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        vga_vsync_dly    <=  1'b0;
    else
        vga_vsync_dly    <=  vga_vsync;
//cmos_vsync_begin:֡ͼ���־�ź�,ÿ����һ��,����ͬ���źŸߵ�ƽ��ʼ
//cmos_vsync_end:֡ͼ���־�ź�,ÿ����һ��,����ͬ���źŵ͵�ƽ��ʼ
assign  cmos_vsync_begin = ((vga_vsync_dly == 1'b1)&& (vga_vsync == 1'b0)) ? 1'b1 : 1'b0;
assign  cmos_vsync_end = ((vga_vsync_dly == 1'b0)&& (vga_vsync == 1'b1)) ? 1'b1 : 1'b0;


//cnt_h:��ͬ���źż�����
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_h   <=  10'd0   ;
    else    if(cnt_h == H_TOTAL - 1'd1)
        cnt_h   <=  10'd0   ;
    else
        cnt_h   <=  cnt_h + 1'd1   ;

//vga_hsync:��ͬ���ź�
assign  vga_hsync = (cnt_h  <=  H_SYNC - 1'd1) ? 1'b0 : 1'b1  ;

//cnt_v:��ͬ���źż�����
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_v   <=  10'd0 ;
    else    if((cnt_v == V_TOTAL - 1'd1) &&  (cnt_h == H_TOTAL-1'd1))
        cnt_v   <=  10'd0 ;
    else    if(cnt_h == H_TOTAL - 1'd1)
        cnt_v   <=  cnt_v + 1'd1 ;
    else
        cnt_v   <=  cnt_v ;

//vga_vsync:��ͬ���ź�,�ߵ�ƽ������Ч
assign  vga_vsync = (cnt_v  <=  V_SYNC - 1'd1) ? 1'b0 : 1'b1  ;

//vga_de1:VGA��Ч��ʾ����
assign  vga_de1 = (((cnt_h >= H_SYNC + H_BACK )
                    && (cnt_h < H_SYNC + H_BACK + H_VALID))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK  + V_VALID)))
                    ? 1'b1 : 1'b0;

//pre_vga_de:��ǰvga_de�ź�1��ʱ������
assign  pre_vga_de = (((cnt_h >= H_SYNC + H_BACK-1 )
                    && (cnt_h < H_SYNC + H_BACK + H_VALID-1))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK  + V_VALID)))
                    ? 1'b1 : 1'b0;

//pix_data_req:���ص�ɫ����Ϣ�����ź�,��ǰvga_de�ź�4��ʱ������
assign  pix_data_req = (((cnt_h >= H_SYNC + H_BACK - 4)
                    && (cnt_h < H_SYNC + H_BACK + H_VALID - 4))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK + V_VALID)))
                    ? 1'b1 : 1'b0;

//pix_data_req1:���ص�ɫ����Ϣ�����ź�,��ǰvga_de�ź�2��ʱ������,β���ӳ�һ����
assign  pix_data_req1 = (((cnt_h >= H_SYNC + H_BACK - 2)
                    && (cnt_h < H_SYNC + H_BACK + H_VALID - 1))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK + V_VALID)))
                    ? 1'b1 : 1'b0;					
					
					
//delete_area:��������128������
wire            				delete_area;	   //�������128������
assign  delete_area = (((cnt_h >= H_SYNC + H_BACK + H_VALID-80)//16*5
                    && (cnt_h < H_SYNC + H_BACK + H_VALID))
                    &&((cnt_v >= V_SYNC + V_BACK-1 )
                    && (cnt_v <V_SYNC + V_BACK)))
                    ? 1'b1 : 1'b0;				
//=======================================================
//���ݲ���
//=======================================================

//����д����read_req�ź�
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		cnt <= 8'b0;
	else if(cnt==15)//Ϊ15ʱ��cnt����һ��
		cnt <= 8'b0;
	else if(pix_data_req == 1'b1||delete_area== 1'b1)
		cnt <= cnt+1'b1;
	else 
		cnt <= cnt;
// assign	read_req=(pix_data_req == 1'b1&&(cnt<=5'd2))?1'b1:1'b0;
assign	read_req=((pix_data_req == 1'b1||delete_area== 1'b1)&&(cnt<8'd1))?1'b1:1'b0;

//д����read_req�źŴ�һ��
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		read_req1 <= 1'b0;
	else 
		read_req1 <= read_req;

//д����read_req1�źŴ�һ��
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		read_req2 <= 1'b0;
	else 
		read_req2 <= read_req1;

//data_reg1�źżĴ�
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            data_reg1    <=  0;
        end
    else    if(pix_data_req == 1'b1)//�ڳ�ǰ��Ч��Χ��
        begin
            if(read_req1 == 1'b1)//д�����һ���ź���Ч
				data_reg1    <=  {read_data};
            else
                data_reg1    <=  data_reg1;
        end
    else
        begin
            data_reg1    <=  0;
            data_reg    <=  data_reg;
        end		
		
//data_reg��ֵ
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n) begin
		data_reg <= 0;
		data <= 0;
    end
	else if(read_req2==1) begin
		data <= data_reg[7:0];//�ڸ�ֵdata_regʱ����Ĵ����ڲ����
		data_reg <= data_reg1;
    end
	else if(pix_data_req1==1) begin
			data <= data_reg[7:0];
			data_reg <= {8'b0,data_reg[USER_DATA_WIDTH-1:8]};//��ǰ��ʹӺ����
		end
	else begin
		data <= 0;
		data_reg <= data_reg;
	end

//=======================================================
//vga��Ч��ʾ�������ص�����
//=======================================================
wire    [9:0]   pix_x;   //���VGA��Ч��ʾ�������ص�X������
wire    [9:0]   pix_y;   //���VGA��Ч��ʾ�������ص�Y������
reg     [9:0]   pix_x_cnt;   //���VGA��Ч��ʾ�������ص�X������
reg     [9:0]   pix_y_cnt;   //���VGA��Ч��ʾ�������ص�Y������
wire            vga_de_begin;   //��Ч�źſ�ʼ

//���vga_de��������
//vga_vsync_dly:vga�����ͬ���źŴ���,���ڲ���cmos_vsync_begin
reg        vga_de_dly;  //vga_de����
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        vga_de_dly    <=  1'b0;
    else
        vga_de_dly    <=  vga_de1;
assign  vga_de_begin = ((vga_de_dly == 1'b1)&& (vga_de1 == 1'b0)) ? 1'b1 : 1'b0;


//pix_x_cnt:X�����������,��ǰ���������ص�һ��ʱ�����ڣ�ʹ�����ǿ��Ը��ݸ����������ֵ���и�ֵ
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        pix_x_cnt   <=  10'd0   ;
    else    if(pre_vga_de == 1'd1)
        pix_x_cnt   <=  pix_x_cnt + 1'd1   ;
    else
        pix_x_cnt   <=  10'd0   ;

//pix_y_cnt:Y�����������
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        pix_y_cnt   <=  10'd0   ;
    else    if(vga_de_begin == 1'd1)
        pix_y_cnt   <=  pix_y_cnt + 1'd1   ;
    else    if(pix_y_cnt == V_VALID)
        pix_y_cnt   <=  10'd0   ;
    else
        pix_y_cnt   <= pix_y_cnt;

assign pix_x=pix_x_cnt;
assign pix_y=pix_y_cnt;

//=======================================================
//�ַ���ʾ����
//=======================================================
reg     [255:0] char [63:0];    //�ַ�����
reg     [63:0] ca_shang [15:0];    //�ַ�����
reg     [71:0] zhen_kong [15:0];   //�ַ�����
reg     [63:0] zhe_zhou [15:0];    //�ַ�����
reg     [55:0] zang_wu [15:0];    //�ַ�����


reg     [7:0] xiaoshudian [15:0];  //�ַ�����
reg     [7:0] zero [15:0];  //�ַ�����
reg     [7:0] one  [15:0];  //�ַ�����
reg     [7:0] two  [15:0];  //�ַ�����
reg     [7:0] three [15:0];  //�ַ�����
reg     [7:0] four  [15:0];  //�ַ�����
reg     [7:0] five  [15:0];  //�ַ�����
reg     [7:0] six [15:0];  //�ַ�����
reg     [7:0] seven  [15:0];  //�ַ�����
reg     [7:0] eight  [15:0];  //�ַ�����
reg     [7:0] nine  [15:0];  //�ַ�����

//=======================================================
//�ַ���ʾ���ص�����
//=======================================================
parameter   CHAR_B_H=   10'd20 ,   //�ַ���ʼX������
            CHAR_B_V=   10'd10 ;   //�ַ���ʼY������
parameter   CHAR_W  =   10'd72 ,   //�ַ����
            CHAR_H  =   10'd16  ;   //�ַ��߶�
wire    [9:0]   char_x  ;   //�ַ���ʾX������
wire    [9:0]   char_y  ;   //�ַ���ʾY������
wire     flag;   //�Ƿ�����ַ����ص�flag

//=======================================================
//�ַ���ʾ���ݸ�ֵ
//=======================================================

parameter   BLACK   =   8'h00,   //��ɫ
            WHITE   =   8'hFF;   //��ɫ
reg     [7:0] data1;   //�ַ�����

//���8λ���ݸ�ֵ
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data1<= data;
    else    if( flag== 1'b1)//�ַ�����y
        data1    <=  WHITE;//�������ַ���ʾ�������ڸ�����������Ϊ1ʱ������ʾ
    else
        data1    <=  data;

//=======================================================
//�������
//=======================================================
wire [23:0] vga_rgb1;
//vga_rgb:������ص�ɫ����Ϣ
assign  vga_de=vga_de_dly;
// assign  vga_rgb = (vga_de1 == 1'b1) ? {data,data,data} : 24'b0 ;
assign  vga_rgb = (vga_de == 1'b1) ? {data1,data1,data1} : 24'b0 ;
assign  vga_clk = clk;

//=======================================================
//����
//=======================================================
reg    [9:0]   text_x;   //������ʼ��x����
reg    [9:0]   text_y;   //������ʼ��y����
//����һ����֡���仯������
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            text_x   <=  0 ;
            text_y   <=  0 ;
        end
    else    if(cmos_vsync_begin == 1'd1)//һ֡�仯һ��
        begin
            text_x   <=  text_x + 1'd1   ;
            text_y   <=  text_y + 1'd1   ;
        end
    else    if(text_x == H_VALID-1)
        text_x   <=  10'd0   ;
    else    if(text_y == V_VALID-1)
        text_y   <=  10'd0   ;
    else
        begin
            text_x   <=  text_x ;
            text_y   <=  text_y ;
        end
		
//=======================================================
//���մ���Ŀ�
//=======================================================
parameter number=4;
reg   [9:0] zuoshang_x_rec [number:0] ;
reg   [9:0] zuoshang_y_rec [number:0] ;
reg   [9:0] youxia_x_rec [number:0] ;
reg   [9:0] youxia_y_rec [number:0] ;
reg   [13:0] acc_rec [number:0] ;
reg   [2:0] label_rec [number:0] ;
reg   [3:0] rec_cnt;


//���single_rec������/�½���
reg        single_rec_dly;  
wire       single_rec_begin;   
wire       single_rec_end;   
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        single_rec_dly    <=  1'b0;
    else
        single_rec_dly    <=  single_rec;
assign  single_rec_begin = ((single_rec_dly == 1'b0)&& (single_rec == 1'b1)) ? 1'b1 : 1'b0;
assign  single_rec_end = ((single_rec_dly == 1'b1)&& (single_rec == 1'b0)) ? 1'b1 : 1'b0;

//���all_rec������/�½���
reg        all_rec_dly;  
wire       all_rec_begin;   
wire       all_rec_end;   
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        all_rec_dly    <=  1'b0;
    else
        all_rec_dly    <=  all_rec;
assign  all_rec_begin = ((all_rec_dly == 1'b0)&& (all_rec == 1'b1)) ? 1'b1 : 1'b0;
assign  all_rec_end = ((all_rec_dly == 1'b1)&& (all_rec == 1'b0)) ? 1'b1 : 1'b0;


//�Դ���Ŀ������м���
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0 )
            rec_cnt   <=  0;
    else    if(all_rec == 1'd1 && single_rec_begin == 1'd1)//�����崫������У���ʼһ�δ���
            rec_cnt   <=  rec_cnt + 1'd1   ;
    else    if(all_rec_begin == 1'd1)	//ÿ�ο�ʼ���崫�临λһ��
            rec_cnt   <=  0;		
    else
            rec_cnt   <=  rec_cnt    ;

//��ֵ
integer i;
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0 ) begin
        for(i=0; i<=number; i=i+1)
            begin
                zuoshang_x_rec[i][9:0] <= 0;
                zuoshang_y_rec[i][9:0] <= 0;
                youxia_x_rec[i][9:0]   <= 0;
                youxia_y_rec[i][9:0]   <= 0;
                acc_rec[i][13:0]       <= 0;
                label_rec[i][2:0]      <= 0;
            end
    end 
    else    if(all_rec == 1'd1 && single_rec_end == 1'd1)//�����崫������У�����һ�δ���
        begin
            zuoshang_x_rec[rec_cnt][9:0] <= zuoshang_x;
            zuoshang_y_rec[rec_cnt][9:0] <= zuoshang_y;
            youxia_x_rec[rec_cnt][9:0]   <= youxia_x;
            youxia_y_rec[rec_cnt][9:0]   <= youxia_y;
            acc_rec[rec_cnt][13:0]       <= acc;
            label_rec[rec_cnt][2:0]      <= label;
        end 
    else begin
            zuoshang_x_rec[rec_cnt][9:0] <= zuoshang_x_rec[rec_cnt][9:0];
            zuoshang_y_rec[rec_cnt][9:0] <= zuoshang_y_rec[rec_cnt][9:0];
            youxia_x_rec[rec_cnt][9:0]   <= youxia_x_rec[rec_cnt][9:0];
            youxia_y_rec[rec_cnt][9:0]   <= youxia_y_rec[rec_cnt][9:0];
            acc_rec[rec_cnt][13:0]       <= acc_rec[rec_cnt][13:0];
            label_rec[rec_cnt][2:0]      <= label_rec[rec_cnt][2:0];
    end



//=======================================================
//�����ʾ�����ÿ����������ʾ4����
//=======================================================

wire     flag1;   //��1����Ԫ��
wire     flag2;   //��2����Ԫ��
wire     flag3;   //��3����Ԫ��
wire     flag4;   //��4����Ԫ��
wire     rec1;   //��1����Ԫ��
wire     rec2;   //��2����Ԫ��
wire     rec3;   //��3����Ԫ��
wire     rec4;   //��4����Ԫ��

//��һ�����ο���ʾ��Ԫ
flag_generate flag_generate_inst1(
    .clk             (clk     ),      //ʱ���ź�
    .sys_rst_n       (sys_rst_n   ),  //��λ�ź�

    .pix_x           (pix_x     ),     //����VGA��Ч��ʾ����
    .pix_y           (pix_y    ),      //����VGA��Ч��ʾ����

    .zuoshang_x       (zuoshang_x_rec[1][9:0] ),   //���Ͽ�x
    .zuoshang_y       (zuoshang_y_rec[1][9:0] ),   //���Ͽ�y
    .youxia_x         (youxia_x_rec[1][9:0]   ),   //���¿�x
    .youxia_y         (youxia_y_rec[1][9:0]   ),   //���¿�y

    .start       	  (all_rec_end ),   //����bin2bcd
    .acc   			  (acc_rec[1][13:0]     ),   //���Ŷ�
	
    .label            (label_rec[1][2:0]    ),   //��ǩ

    .flag             (flag1      )    //���������Ԫ��flag
);

//�ڶ������ο���ʾ��Ԫ
flag_generate flag_generate_inst2(
    .clk             (clk     ),      //ʱ���ź�
    .sys_rst_n       (sys_rst_n   ),  //��λ�ź�

    .pix_x           (pix_x     ),     //����VGA��Ч��ʾ����
    .pix_y           (pix_y    ),      //����VGA��Ч��ʾ����

    .zuoshang_x       (zuoshang_x_rec[2][9:0]),   //���Ͽ�x
    .zuoshang_y       (zuoshang_y_rec[2][9:0]),   //���Ͽ�y
    .youxia_x         (youxia_x_rec[2][9:0]  ),   //���¿�x
    .youxia_y         (youxia_y_rec[2][9:0]  ),   //���¿�y

    .start       	  (all_rec_end ),   //����bin2bcd
    .acc   			  (acc_rec[2][13:0]        ),   //���Ŷ�
	
    .label            (label_rec[2][2:0]      ),   //��ǩ

    .flag             (flag2      )    //���������Ԫ��flag
);

//���������ο���ʾ��Ԫ
flag_generate flag_generate_inst3(
    .clk             (clk     ),      //ʱ���ź�
    .sys_rst_n       (sys_rst_n   ),  //��λ�ź�

    .pix_x           (pix_x     ),     //����VGA��Ч��ʾ����
    .pix_y           (pix_y    ),      //����VGA��Ч��ʾ����

    .zuoshang_x       (zuoshang_x_rec[3][9:0] ),   //���Ͽ�x
    .zuoshang_y       (zuoshang_y_rec[3][9:0] ),   //���Ͽ�y
    .youxia_x         (youxia_x_rec[3][9:0]   ),   //���¿�x
    .youxia_y         (youxia_y_rec[3][9:0]   ),   //���¿�y


    .start       	  (all_rec_end ),   //����bin2bcd
    .acc   			  (acc_rec[3][13:0]        ),   //���Ŷ�
	
    .label            (label_rec[3][2:0]      ),   //��ǩ

    .flag             (flag3      )    //���������Ԫ��flag
);

//���ĸ����ο���ʾ��Ԫ
flag_generate flag_generate_inst4(
    .clk             (clk     ),      //ʱ���ź�
    .sys_rst_n       (sys_rst_n   ),  //��λ�ź�

    .pix_x           (pix_x     ),     //����VGA��Ч��ʾ����
    .pix_y           (pix_y    ),      //����VGA��Ч��ʾ����

    .zuoshang_x       (zuoshang_x_rec[4][9:0] ),   //���Ͽ�x
    .zuoshang_y       (zuoshang_y_rec[4][9:0] ),   //���Ͽ�y
    .youxia_x         (youxia_x_rec[4][9:0]   ),   //���¿�x
    .youxia_y         (youxia_y_rec[4][9:0]   ),   //���¿�y

    .start       	  (all_rec_end ),   //����bin2bcd
    .acc   			  (acc_rec[4][13:0]        ),   //���Ŷ�
	
    .label            (label_rec[4][2:0]      ),   //��ǩ

    .flag             (flag4      )    //���������Ԫ��flag
);


//=======================================================
//ֻ��ʾһ֡�ұ�����ʾһ֡�Ŀ��Ƶ�Ԫ
//=======================================================
reg done_flag;
reg display;
reg        display_dly;  
wire       display_begin;   
wire       display_end;  

always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        done_flag    <=  1'b0;
    else if (all_rec_end==1) //����������,��done_flag����Ϊ1
        done_flag    <=  1; 
    else if (display_end==1) //�����ʾ�ź���ɣ�����һ����ʾ��ϣ���done�źŻ�ԭΪ0
        done_flag    <=  0; 
    else
        done_flag    <=  done_flag;

//�Ƿ�չ��ʾ��flag

always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        display    <=  1'b0;
    else if (done_flag==1 && (cmos_vsync_end)) //����������,������֡ͷ������Խ�����ʾ
        display    <=  1; 
    else if (display==1  && (cmos_vsync_begin)) //�����ʾ��Ч,������֡β,��һ����ʾ���
        display    <=  0; 
    else
        display    <=  display;

//���display������/�½���
 
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        display_dly    <=  1'b0;
    else
        display_dly    <=  display;
assign  display_begin = ((display_dly == 1'b0)&& (display == 1'b1)) ? 1'b1 : 1'b0;
assign  display_end = ((display_dly == 1'b1)&& (display == 1'b0)) ? 1'b1 : 1'b0;


//=======================================================
//���
//=======================================================

assign rec1 = flag1&&(1<=num_rec); //������������ڵ���1ʱ��flag1��Ч
assign rec2 = flag2&&(2<=num_rec);
assign rec3 = flag3&&(3<=num_rec);
assign rec4 = flag4&&(4<=num_rec);

assign flag =  rec1 || rec2 || rec3 || rec4;//������ַ�һ����ʾ


endmodule