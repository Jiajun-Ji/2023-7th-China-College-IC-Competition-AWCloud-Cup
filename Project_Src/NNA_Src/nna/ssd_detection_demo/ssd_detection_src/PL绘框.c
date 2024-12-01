
//六buffer

//gcc标准头文件
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include "tupian.h"
#include "tupian2.h"
#include "tupian3.h"
#include "tupian4.h"
#include "tupian5.h"
//hps 厂家提供的底层定义头文件
#define soc_cv_av	//定义使用soc_cv_av硬件平台

#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"

//与用户具体HPS应用系统相关的硬件描述头文件
#include "hps_0.h"

#define HW_REGS_BASE (ALT_STM_OFST )	//HPS外设地址段基地址
#define HW_REGS_SPAN (0x04000000 )		//HPS外设地址段地址空间
#define HW_REGS_MASK (HW_REGS_SPAN - 1 )	//HPS外设地址段地址掩码

/*构造设备ioclt命令*/
#define AMM_WR_MAGIC 'x'
#define AMM_WR_CMD_DMA_BASE  _IOR(AMM_WR_MAGIC,0x1a,int)

/*fpga write master control寄存器位映射*/
#define CTRL_GO_MASK  		(1<<0)
#define CTRL_RESET_MASK  	(1<<1)
#define CTRL_MODE_MASK  	(1<<2)

#define DEVICE_NAME "/dev/amm_wr"	/*定义设备名称*/

//定义一次传输数据长度
#define data_length 512//写入字节长度为512
#define int_length data_length/4//根据写入字节长度求出int长度
#define IMG_WIDTH  400
#define IMG_HEIGHT 320
#define IMG_BUF_SIZE IMG_WIDTH * IMG_HEIGHT * 3
//虚拟地址，PS端需要
static volatile unsigned long *master_ctrl_virtual_base = NULL;	//写主机控制模块虚拟地址
static volatile unsigned int *ddr3_vga_cfg_base = NULL;//ddr3_vga控制模块虚拟地址(官方)
static volatile unsigned int *ddr3_vga_top_virtual_base = NULL;//ddr3_vga_top控制模块虚拟地址(自己的ip)
static unsigned char *transfer_data_base = NULL;//dma虚拟地址，便于hps操控
//物理地址，PL端需要
static volatile unsigned long dma_base; /*DMA传输物理基地址*/

int fpga_init(long int *virtual_base) {
	int fd;
	void *periph_virtual_base;	//外设空间虚拟地址

	//打开MPU
	if ((fd = open("/dev/mem", ( O_RDWR | O_SYNC))) == -1) {
		printf("ERROR: could not open \"/dev/mem\"...\n");
		return (1);
	}

	//将外设地址段映射到用户空间
	periph_virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE),
	MAP_SHARED, fd, HW_REGS_BASE);
	if (periph_virtual_base == MAP_FAILED) {
		printf("ERROR: mmap() failed...\n");
		close(fd);
		return (1);
	}

	//映射得到写主机控制模块虚拟地址(dvp_ddr3_top)
	master_ctrl_virtual_base = periph_virtual_base
			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + DVP_DDR3_TOP_0_BASE)
					& (unsigned long) ( HW_REGS_MASK));

	//映射得到写主机控制模块虚拟地址(ddr3_vga_top)
	ddr3_vga_top_virtual_base = periph_virtual_base
			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + DDR3_VGA_TOP_0_BASE)
					& (unsigned long) ( HW_REGS_MASK));

	//映射得到ddr3_vga控制模块虚拟地址
	ddr3_vga_cfg_base = (unsigned int *)(periph_virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + DDR3_VGA_0_BASE) & (unsigned long)(HW_REGS_MASK)));

	*virtual_base = periph_virtual_base; //将外设虚拟地址保存，用以释放时候使用
	return fd;
}

int sample_init(void) {
	int fd;
	fd = open(DEVICE_NAME, O_RDWR);
	if (fd == 1) {
		perror("open error\n");
		exit(-1);
	}

	ioctl(fd, AMM_WR_CMD_DMA_BASE, &dma_base); /*从内核空间读取DMA内存的物理地址*/
	printf("dma_base is %x\n", dma_base);

	//配置dvp_ddr3_top
	master_ctrl_virtual_base[1] = dma_base; /*将DMA内存的物理地址写入主机控制模块的寄存器1*/
	master_ctrl_virtual_base[2] = IMG_BUF_SIZE; /*指定主机写入数据长度*/

	//配置ddr3_vga
	*ddr3_vga_cfg_base = dma_base + IMG_BUF_SIZE;
	*(ddr3_vga_cfg_base + 1) = IMG_BUF_SIZE;
	*(ddr3_vga_cfg_base + 2) = 0x00000000;

	return fd;
}

int main(int argc, char ** argv) {

	int dma_fd;
	int fpga_fd;
	int virtual_base = 0;	//虚拟基地址
	unsigned char read_buffer[IMG_BUF_SIZE] = { 0 }; /*用户空间数据buffer*/
	int retval;
	int i;
	unsigned char mode = 0; /*FPGA侧数据累加计数器起始值模式设定*/

	//完成fpga侧外设虚拟地址映射
	fpga_fd = fpga_init(&virtual_base);

	/*初始化写主机控制参数*/
	dma_fd = sample_init();

	//将dma基地址处IMG_BUF_SIZE * 3大小 的空间映射位虚拟
	transfer_data_base = (unsigned char *)mmap(NULL, IMG_BUF_SIZE * 6, (PROT_READ | PROT_WRITE), MAP_SHARED, fpga_fd, dma_base);
	//ddr3_vga开始工作
//	*(ddr3_vga_cfg_base + 2) = 0x00000001;
	//启动vga
	ddr3_vga_top_virtual_base[1] = dma_base+ IMG_BUF_SIZE* 2;/*将DMA内存的物理地址写入主机控制模块的寄存器1*/
	ddr3_vga_top_virtual_base[2] = IMG_BUF_SIZE; /*指定主机写入数据长度*/
	ddr3_vga_top_virtual_base[0] = CTRL_GO_MASK; /*启动传输并设置数据累加起始值为0*/
	//启动dvp
	master_ctrl_virtual_base[1] = dma_base; /*将DMA内存的物理地址写入主机控制模块的寄存器1*/
	master_ctrl_virtual_base[2] = IMG_BUF_SIZE; /*指定主机写入数据长度*/
	master_ctrl_virtual_base[0] = CTRL_GO_MASK; /*启动传输并设置数据累加起始值为0*/


//测试写入并读出数据
while(1)
{

		//传输
		//输出一帧图像
		if(master_ctrl_virtual_base[3] == 0x1)//该值为1代表着dvp写入的是buffer0，则从buffer1中读
		{
			printf("write buffer0\n");
			memcpy(transfer_data_base + IMG_BUF_SIZE* 2, transfer_data_base+ 5*IMG_BUF_SIZE, IMG_BUF_SIZE);//vga写buffer3
			ddr3_vga_top_virtual_base[1] = dma_base + IMG_BUF_SIZE * 3;//vga读buffer4
			ddr3_vga_top_virtual_base[2] = IMG_BUF_SIZE;
		}
		else//该值为0代表着dvp写入的是buffer1，则从buffer0中读
		{
			printf("write buffer1\n");
			memcpy(transfer_data_base + IMG_BUF_SIZE * 3, transfer_data_base+ 4*IMG_BUF_SIZE , IMG_BUF_SIZE);//vga写buffer4
			ddr3_vga_top_virtual_base[1] = dma_base + IMG_BUF_SIZE * 2;//vga读buffer3
			ddr3_vga_top_virtual_base[2] = IMG_BUF_SIZE;
		}
}



	//程序退出前，取消虚拟地址映射
	if (munmap(virtual_base, HW_REGS_SPAN) != 0) {
		printf("ERROR: munmap() failed...\n");
		close(fpga_fd);
		return (1);
	}
	close(fpga_fd);
	close(dma_fd); //关闭MPU
	return 0;
}






//单通道/三通道不使用6buffer

//gcc标准头文件
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include "tupian.h"
#include "tupian2.h"
#include "tupian3.h"
#include "tupian4.h"
#include "tupian5.h"
//hps 厂家提供的底层定义头文件
#define soc_cv_av	//定义使用soc_cv_av硬件平台

#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"

//与用户具体HPS应用系统相关的硬件描述头文件
#include "hps_0.h"

#define HW_REGS_BASE (ALT_STM_OFST )	//HPS外设地址段基地址
#define HW_REGS_SPAN (0x04000000 )		//HPS外设地址段地址空间
#define HW_REGS_MASK (HW_REGS_SPAN - 1 )	//HPS外设地址段地址掩码

/*构造设备ioclt命令*/
#define AMM_WR_MAGIC 'x'
#define AMM_WR_CMD_DMA_BASE  _IOR(AMM_WR_MAGIC,0x1a,int)

/*fpga write master control寄存器位映射*/
#define CTRL_GO_MASK  		(1<<0)
#define CTRL_RESET_MASK  	(1<<1)
#define CTRL_MODE_MASK  	(1<<2)

#define DEVICE_NAME "/dev/amm_wr"	/*定义设备名称*/

//定义一次传输数据长度
#define data_length 512//写入字节长度为512
#define int_length data_length/4//根据写入字节长度求出int长度
#define IMG_WIDTH  400
#define IMG_HEIGHT 320
#define IMG_BUF_SIZE IMG_WIDTH * IMG_HEIGHT
#define RESIZE_IMG_BUF_SIZE IMG_WIDTH * IMG_HEIGHT//resize一帧的大小

//虚拟地址，PS端需要
static volatile unsigned long *master_ctrl_virtual_base = NULL;	//写主机控制模块虚拟地址
static volatile unsigned int *ddr3_vga_cfg_base = NULL;//ddr3_vga控制模块虚拟地址(官方)
static volatile unsigned int *ddr3_vga_top_virtual_base = NULL;//ddr3_vga_top控制模块虚拟地址(自己的ip)
static volatile unsigned int *plot_virtual_base = NULL;//绘框模块(自己的ip)
static unsigned char *transfer_data_base = NULL;//dma虚拟地址，便于hps操控
//物理地址，PL端需要
static volatile unsigned long dma_base; /*DMA传输物理基地址*/

int fpga_init(long int *virtual_base) {
	int fd;
	void *periph_virtual_base;	//外设空间虚拟地址

	//打开MPU
	if ((fd = open("/dev/mem", ( O_RDWR | O_SYNC))) == -1) {
		printf("ERROR: could not open \"/dev/mem\"...\n");
		return (1);
	}

	//将外设地址段映射到用户空间
	periph_virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE),
	MAP_SHARED, fd, HW_REGS_BASE);
	if (periph_virtual_base == MAP_FAILED) {
		printf("ERROR: mmap() failed...\n");
		close(fd);
		return (1);
	}

	//映射得到写主机控制模块虚拟地址(dvp_ddr3_top)
	master_ctrl_virtual_base = periph_virtual_base
			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + DVP_DDR3_TOP_0_BASE)
					& (unsigned long) ( HW_REGS_MASK));

	//映射得到写主机控制模块虚拟地址(ddr3_vga_top)
	ddr3_vga_top_virtual_base = periph_virtual_base
			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + DDR3_VGA_TOP_0_BASE)
					& (unsigned long) ( HW_REGS_MASK));

	//映射得到绘框模块plot模块虚拟地址(plot_ctrl)
	plot_virtual_base = periph_virtual_base
			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + PLOT_VGA_TOP_0_BASE)
					& (unsigned long) ( HW_REGS_MASK));


	//映射得到ddr3_vga控制模块虚拟地址
	ddr3_vga_cfg_base = (unsigned int *)(periph_virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + DDR3_VGA_0_BASE) & (unsigned long)(HW_REGS_MASK)));

	*virtual_base = periph_virtual_base; //将外设虚拟地址保存，用以释放时候使用
	return fd;
}

int sample_init(void) {
	int fd;
	fd = open(DEVICE_NAME, O_RDWR);
	if (fd == 1) {
		perror("open error\n");
		exit(-1);
	}

	ioctl(fd, AMM_WR_CMD_DMA_BASE, &dma_base); /*从内核空间读取DMA内存的物理地址*/
	printf("dma_base is %x\n", dma_base);

	//配置dvp_ddr3_top
	master_ctrl_virtual_base[1] = dma_base; /*将DMA内存的物理地址写入主机控制模块的寄存器1*/
	master_ctrl_virtual_base[2] = IMG_BUF_SIZE; /*指定主机写入数据长度*/

	//配置ddr3_vga
	*ddr3_vga_cfg_base = dma_base + IMG_BUF_SIZE;
	*(ddr3_vga_cfg_base + 1) = IMG_BUF_SIZE;
	*(ddr3_vga_cfg_base + 2) = 0x00000000;

	return fd;
}

int main(int argc, char ** argv) {

	int dma_fd;
	int fpga_fd;
	int virtual_base = 0;	//虚拟基地址
	unsigned char read_buffer[IMG_BUF_SIZE] = { 0 }; /*用户空间数据buffer*/
	unsigned char resize_buffer[RESIZE_IMG_BUF_SIZE] = { 0 }; /*用户空间数据buffer*/
	int retval;
	int i;
	unsigned char mode = 0; /*FPGA侧数据累加计数器起始值模式设定*/

	//完成fpga侧外设虚拟地址映射
	fpga_fd = fpga_init(&virtual_base);

	/*初始化写主机控制参数*/
	dma_fd = sample_init();

	//将dma基地址处IMG_BUF_SIZE * 3大小 的空间映射位虚拟
	transfer_data_base = (unsigned char *)mmap(NULL, IMG_BUF_SIZE * 6, (PROT_READ | PROT_WRITE), MAP_SHARED, fpga_fd, dma_base);
	//ddr3_vga开始工作
//	*(ddr3_vga_cfg_base + 2) = 0x00000001;
	//启动vga
	ddr3_vga_top_virtual_base[1] = dma_base+ IMG_BUF_SIZE* 2;/*将DMA内存的物理地址写入主机控制模块的寄存器1*/
	ddr3_vga_top_virtual_base[2] = IMG_BUF_SIZE; /*指定主机写入数据长度*/
	ddr3_vga_top_virtual_base[0] = CTRL_GO_MASK; /*启动传输并设置数据累加起始值为0*/
	//启动dvp
	master_ctrl_virtual_base[1] = dma_base; /*将DMA内存的物理地址写入主机控制模块的寄存器1*/
	master_ctrl_virtual_base[2] = IMG_BUF_SIZE; /*指定主机写入数据长度*/
	master_ctrl_virtual_base[0] = CTRL_GO_MASK; /*启动传输并设置数据累加起始值为0*/
//	//复位

	//绘框ip
	plot_virtual_base[0] = 0 ;     //总体传输寄存器
	plot_virtual_base[1] = 0 ;     //单个框传输传输寄存器,可以使用该寄存器表示数据准备好一次
	plot_virtual_base[2] = 0 ;     //传输个数寄存器
	plot_virtual_base[3] = 0 ;	   //框左上x坐标寄存器
	plot_virtual_base[4] = 0 ;	   //框左上y坐标寄存器
	plot_virtual_base[5] = 0 ;	   //框右下x坐标寄存器
	plot_virtual_base[6] = 0 ;	   //框右下y坐标寄存器
	plot_virtual_base[7] = 0 ;	   //框标签寄存器
	plot_virtual_base[8] = 0 ;	   //框置信度寄存器

	int plot_cnt=0;
	int acc_cnt=0;
	int num_rec=4;
	int c=0;
//测试写入并读出数据
while(1)
{

	plot_virtual_base[2] = num_rec ;     		 //传输个数设置为num_rec
    plot_virtual_base[0] = 1 ;     		 //启动一次传输
    //传输开始
	for (c = 0; c < num_rec; c++)
	{
		printf(" %d:\r\n ",c);
		plot_virtual_base[1] = 1 ;    		 //单次传输开始
		//单次传输
		plot_virtual_base[3] = 20 +10*c*plot_cnt;	   		 //框左上x坐标寄存器
		plot_virtual_base[4] = 10 +10*c*plot_cnt;	  		 //框左上y坐标寄存器
		plot_virtual_base[5] = 90 +10*c*plot_cnt;	  		 //框右下x坐标寄存器
		plot_virtual_base[6] = 100+10*c*plot_cnt;   		     //框右下y坐标寄存器
		plot_virtual_base[7] = plot_cnt ; 	             //标签
		plot_virtual_base[8] = 8191+acc_cnt+c ;  		     //框置信度寄存器
		//单次传输
		plot_virtual_base[1] = 0 ;    		 //单次传输结束
	}
    //传输结束
    plot_virtual_base[0] = 0 ;    		 //终止一次传输


	plot_cnt++;
	acc_cnt++;
	if(plot_cnt==5)
		plot_cnt=1;

	int d=0;
	for (d = 0; d < 9; d++)
	{
		printf(" %d: ",d);
		printf(" %d\r\n",plot_virtual_base[d]);
	}
	if(acc_cnt%100==0)
		num_rec--;

	usleep(100000);


}


////测试写入并读出数据
//while(1)
//{
//
//		//输出一帧图像
//		if(master_ctrl_virtual_base[3] == 0x1)//该值为1代表着dvp写入的是buffer0，则从buffer1中读
//		{
//			printf("write buffer0\n");
//			memcpy(transfer_data_base + IMG_BUF_SIZE* 2, transfer_data_base+ IMG_BUF_SIZE, IMG_BUF_SIZE);//hps将buffer1复制到buffer2
//			ddr3_vga_top_virtual_base[1] = dma_base + IMG_BUF_SIZE * 3;//vga读buffer4
//			ddr3_vga_top_virtual_base[2] = IMG_BUF_SIZE;
//		}
//		else//该值为0代表着dvp写入的是buffer1，则从buffer0中读
//		{
//			printf("write buffer1\n");
//			memcpy(transfer_data_base + IMG_BUF_SIZE * 3, transfer_data_base , IMG_BUF_SIZE);//hps将buffer0复制到buffer3
//			ddr3_vga_top_virtual_base[1] = dma_base + IMG_BUF_SIZE * 2;//vga读buffer2
//			ddr3_vga_top_virtual_base[2] = IMG_BUF_SIZE;
//		}
//}

	//程序退出前，取消虚拟地址映射
	if (munmap(virtual_base, HW_REGS_SPAN) != 0) {
		printf("ERROR: munmap() failed...\n");
		close(fpga_fd);
		return (1);
	}
	close(fpga_fd);
	close(dma_fd); //关闭MPU
	return 0;
}





//
////测试数据重排
//
////gcc标准头文件
//#include <stdio.h>
//#include <unistd.h>
//#include <fcntl.h>
//#include <sys/mman.h>
//#include <stdlib.h>
//#include <sys/ioctl.h>
//#include "tupian.h"
//#include "tupian2.h"
//#include "tupian3.h"
//#include "tupian4.h"
//#include "tupian5.h"
////hps 厂家提供的底层定义头文件
//#define soc_cv_av	//定义使用soc_cv_av硬件平台
//
//#include "hwlib.h"
//#include "socal/socal.h"
//#include "socal/hps.h"
//
////与用户具体HPS应用系统相关的硬件描述头文件
//#include "hps_0.h"
//
//#define HW_REGS_BASE (ALT_STM_OFST )	//HPS外设地址段基地址
//#define HW_REGS_SPAN (0x04000000 )		//HPS外设地址段地址空间
//#define HW_REGS_MASK (HW_REGS_SPAN - 1 )	//HPS外设地址段地址掩码
//
///*构造设备ioclt命令*/
//#define AMM_WR_MAGIC 'x'
//#define AMM_WR_CMD_DMA_BASE  _IOR(AMM_WR_MAGIC,0x1a,int)
//
///*fpga write master control寄存器位映射*/
//#define CTRL_GO_MASK  		(1<<0)
//#define CTRL_RESET_MASK  	(1<<1)
//#define CTRL_MODE_MASK  	(1<<2)
//
//#define DEVICE_NAME "/dev/amm_wr"	/*定义设备名称*/
//
////定义一次传输数据长度
//#define data_length 512//写入字节长度为512
//#define int_length data_length/4//根据写入字节长度求出int长度
//#define IMG_WIDTH  400
//#define IMG_HEIGHT 320
//#define IMG_BUF_SIZE IMG_WIDTH * IMG_HEIGHT
//#define RESIZE_IMG_BUF_SIZE IMG_WIDTH * IMG_HEIGHT//resize一帧的大小
//
////虚拟地址，PS端需要
//static volatile unsigned long *master_ctrl_virtual_base = NULL;	//写主机控制模块虚拟地址
//static volatile unsigned int *ddr3_vga_cfg_base = NULL;//ddr3_vga控制模块虚拟地址(官方)
//static volatile unsigned int *ddr3_vga_top_virtual_base = NULL;//ddr3_vga_top控制模块虚拟地址(自己的ip)
//static unsigned char *transfer_data_base = NULL;//dma虚拟地址，便于hps操控
////物理地址，PL端需要
//static volatile unsigned long dma_base; /*DMA传输物理基地址*/
//
//int fpga_init(long int *virtual_base) {
//	int fd;
//	void *periph_virtual_base;	//外设空间虚拟地址
//
//	//打开MPU
//	if ((fd = open("/dev/mem", ( O_RDWR | O_SYNC))) == -1) {
//		printf("ERROR: could not open \"/dev/mem\"...\n");
//		return (1);
//	}
//
//	//将外设地址段映射到用户空间
//	periph_virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE),
//	MAP_SHARED, fd, HW_REGS_BASE);
//	if (periph_virtual_base == MAP_FAILED) {
//		printf("ERROR: mmap() failed...\n");
//		close(fd);
//		return (1);
//	}
//
//	//映射得到写主机控制模块虚拟地址(dvp_ddr3_top)
//	master_ctrl_virtual_base = periph_virtual_base
//			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + DVP_DDR3_TOP_0_BASE)
//					& (unsigned long) ( HW_REGS_MASK));
//
//	//映射得到写主机控制模块虚拟地址(ddr3_vga_top)
//	ddr3_vga_top_virtual_base = periph_virtual_base
//			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + DDR3_VGA_TOP_0_BASE)
//					& (unsigned long) ( HW_REGS_MASK));
//
//	//映射得到ddr3_vga控制模块虚拟地址
//	ddr3_vga_cfg_base = (unsigned int *)(periph_virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + DDR3_VGA_0_BASE) & (unsigned long)(HW_REGS_MASK)));
//
//	*virtual_base = periph_virtual_base; //将外设虚拟地址保存，用以释放时候使用
//	return fd;
//}
//
//int sample_init(void) {
//	int fd;
//	fd = open(DEVICE_NAME, O_RDWR);
//	if (fd == 1) {
//		perror("open error\n");
//		exit(-1);
//	}
//
//	ioctl(fd, AMM_WR_CMD_DMA_BASE, &dma_base); /*从内核空间读取DMA内存的物理地址*/
//	printf("dma_base is %x\n", dma_base);
//
//	//配置dvp_ddr3_top
//	master_ctrl_virtual_base[1] = dma_base; /*将DMA内存的物理地址写入主机控制模块的寄存器1*/
//	master_ctrl_virtual_base[2] = IMG_BUF_SIZE; /*指定主机写入数据长度*/
//
//	//配置ddr3_vga
//	*ddr3_vga_cfg_base = dma_base + IMG_BUF_SIZE;
//	*(ddr3_vga_cfg_base + 1) = IMG_BUF_SIZE;
//	*(ddr3_vga_cfg_base + 2) = 0x00000000;
//
//	return fd;
//}
//
//
//
//#define INPUT_EXTEND_SCALE 8
//
//int up_round(int a, int b)//向上取整
//{
//  return (a - 1) / b + 1;
//}
//
////旧的
//void input_reorganized(int8_t *src, int8_t *dst, int in_c, int in_h, int in_w)
//{
//  int input_c = up_round(in_c, INPUT_EXTEND_SCALE);//计算需要进行多少次8通道重排input_c
//  int i,r,c,k;
//  for (i = 0; i < input_c; i++)				   //按顺序对8通道重排
//  {
//    for ( r = 0; r < in_h; r++)				   //对h进行遍历
//    {
//      for ( c = 0; c < in_w; c++)			   //对w进行遍历
//      {
//        for ( k = 0; k < INPUT_EXTEND_SCALE; k++)//按顺序对8通道重排
//        {
//          if (i * INPUT_EXTEND_SCALE + k < in_c)//按顺序对8通道重排
//          {
//            int8_t temp =
//                src[((i * INPUT_EXTEND_SCALE + k) * in_h + r) * in_w + c];
//            dst[((i * in_h + r) * in_w + c) * INPUT_EXTEND_SCALE + k] = temp;
//          }
//          else//按顺序对8通道重排
//          {
//            dst[((i * in_h + r) * in_w + c) * INPUT_EXTEND_SCALE + k] = 0;
//          }
//        }
//      }
//    }
//  }
//}
//
//// 定义一个函数，输入参数为源张量指针，目标张量指针，以及源张量的通道数，高度和宽度
//void input_reorganized1(int8_t *src, int8_t *dst, int in_c, int in_h, int in_w)
//{
//  // 计算需要进行多少次8通道重排，如果源张量的通道数不是8的倍数，就向上取整
//  int input_c = up_round(in_c, INPUT_EXTEND_SCALE);
//  // 定义四个循环变量，分别表示重排后的通道索引，高度索引，宽度索引和重排内部的通道索引
//  int i,r,c,k;
//  // 对重排后的通道进行遍历
//  for (i = 0; i < input_c; i++)
//  {
//    // 对源张量的高度进行遍历
//    for ( r = 0; r < in_h; r++)
//    {
//      // 对源张量的宽度进行遍历
//      for ( c = 0; c < in_w; c++)
//      {
//        // 对重排内部的8个通道进行遍历
//        for ( k = 0; k < INPUT_EXTEND_SCALE; k++)
//        {
//          // 判断是否超出源张量的通道范围
//          if (i * INPUT_EXTEND_SCALE + k < in_c)
//          {
//            // 如果没有超出，就将源张量对应位置的值赋给目标张量对应位置
//            int8_t temp =
//                src[((i * INPUT_EXTEND_SCALE + k) * in_h + r) * in_w + c];
//            dst[((i * in_h + r) * in_w + c) * INPUT_EXTEND_SCALE + k] = temp;
//          }
//          else
//          {
//            // 如果超出了，就将目标张量对应位置赋为0
//            dst[((i * in_h + r) * in_w + c) * INPUT_EXTEND_SCALE + k] = 0;
//          }
//        }
//      }
//    }
//  }
//}
//////新的
////void InputRearrange(int8_t *din,
////                    int8_t *dout,
////                    const int c,
////                    const int h,
////                    const int w,
////                    const int pad)
////{
////#if (ARMREOG_TYPE == ARMREOG_POLL)
////  int8_t *dout_array[INPUT_EXTEND_SCALE];
////
////  int idx_fpga_idata = 0;
////  for (int i = 0; i < up_round(c, INPUT_EXTEND_SCALE); i++)
////  {
////    dout_array[0] = din + i * ((h + 2 * pad) * (w + 2 * pad) * INPUT_EXTEND_SCALE);
////    for (int n = 1; n < INPUT_EXTEND_SCALE; n++)
////    {
////      dout_array[n] = dout_array[n - 1] + (h + 2 * pad) * (w + 2 * pad);
////    }
////    for (int r = 0; r < (h + 2 * pad); r++)
////    {
////      for (int cc = 0; cc < (w + 2 * pad); cc++)
////      {
////        for (int k = 0; k < INPUT_EXTEND_SCALE; k++)
////        {
////          if (k < c)
////            dout[idx_fpga_idata++] = *(dout_array[k]++); //*(dout_array[k] + r * w + cc);  //
////          else
////            dout[idx_fpga_idata++] = 0;
////        }
////      }
////    }
////  }
//
//
//#define h  20
//#define w  20
//#define c  3
//
//int main(int argc, char ** argv) {
//
//	int dma_fd;
//	int fpga_fd;
//	int virtual_base = 0;	//虚拟基地址
//	unsigned char read_buffer[IMG_BUF_SIZE] = { 0 }; /*用户空间数据buffer*/
//	unsigned char resize_buffer[RESIZE_IMG_BUF_SIZE] = { 0 }; /*用户空间数据buffer*/
//	int retval;
//	unsigned char mode = 0; /*FPGA侧数据累加计数器起始值模式设定*/
//
//	//完成fpga侧外设虚拟地址映射
//	fpga_fd = fpga_init(&virtual_base);
//
//	/*初始化写主机控制参数*/
//	dma_fd = sample_init();
//
//	//将dma基地址处IMG_BUF_SIZE * 3大小 的空间映射位虚拟
//	transfer_data_base = (unsigned char *)mmap(NULL, IMG_BUF_SIZE * 6, (PROT_READ | PROT_WRITE), MAP_SHARED, fpga_fd, dma_base);
//
//	//生成300*300*3特征图
//    int i,j,k=0;
//    unsigned char cnt=0;
//	unsigned char src[h*w*c] = {0}; /*src*/
//	for (i = 0; i < c; i++)
//	{
//		for (j = 0; j < h; j++)
//		{
//			for (k = 0; k < w; k++)
//			{
//				src[i*h*w+j*w+k]=cnt;
//				cnt++;
//			}
//		}
//	}
//	printf("\r\n");
//	printf("prereconize");
//	printf("\r\n");
//	int d=0;
//	int cnt1=0;
//	for (d = 0; d < h*w*c; d++)
//	{
//		printf(" %d ",src[d]);
//		if((d+1)%w==0 && d!=0)
//		{
//			cnt1++;
//			printf("            %d\r\n",cnt1);
//		}
//		if((d+1)%(h*w)==0 && d!=0)
//			printf("\r\n");
//	}
//	printf("\r\n");
//	printf("reconize");
//	printf("\r\n");
//	//进行数据重排并打印
//	unsigned char dst[500*500*8] = {0}; /*src*/
//	cnt1=0;
//	input_reorganized(src,dst,c,h,w);
//	for (d = 0; d < (up_round(c, INPUT_EXTEND_SCALE))*h*w*INPUT_EXTEND_SCALE; d++)
//	{
//
//		printf(" %d ",dst[d]);
//		if((d+1)%INPUT_EXTEND_SCALE==0 && d!=0)
//		{
//			cnt1++;
//			printf("            %d\r\n",cnt1);
//		}
////		if((d+1)%(h*w)==0 && d!=0)
////			printf("\r\n");
//	}
//
//
////	//测试写入并读出数据
////	while(1)
////	{
////		//生成对应的特征图
////
////
////
////	}
//
//	//程序退出前，取消虚拟地址映射
//	if (munmap(virtual_base, HW_REGS_SPAN) != 0) {
//		printf("ERROR: munmap() failed...\n");
//		close(fpga_fd);
//		return (1);
//	}
//	close(fpga_fd);
//	close(dma_fd); //关闭MPU
//	return 0;
//}


