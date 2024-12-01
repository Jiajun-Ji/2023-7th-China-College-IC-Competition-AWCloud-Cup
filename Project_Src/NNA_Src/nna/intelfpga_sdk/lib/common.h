#ifndef __COMMON_H__
#define __COMMON_H__


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>

#include "intelfpga.h"


// Version
#define CMA_VERSION 0x01000000

// Board name
#define CMA_BRDNAME "c5soc"
#define CMA_DRVNAME "cmadrv"

// Memory block
struct cma_blk_s {
	void* addr; // base address
	void* virt; // kernel address
	unsigned long phys; // Pysical address
	size_t size; // size in bytes
};

// Memory copy
struct cma_cpy_s {
	unsigned long dst; // DST address
	unsigned long src; // SRC address
	size_t        len; // size in bytes
};

#define CMA_MAGIC_ID (('C' + 'M' + 'A' + 'B') / 4)

/* Ioctls */
#define CMA_IOCTL_MAKE(cmd)  ( _IO( CMA_MAGIC_ID, cmd))
#define CMA_IOCTL_GET(cmd)   ( _IOC_NR(cmd))
#define CMA_IOCTL_VALID(cmd) ((_IOC_TYPE(cmd)==CMA_MAGIC_ID) ? 1 : 0)

#define CMA_CMD_ALLOC      0x00 // struct cma_blk_s
#define CMA_CMD_FREE       0x01 // struct cma_blk_s
#define CMA_CMD_MCPY       0x10 // struct cma_cpy_s
#define CMA_CMD_SHOW       0x20 // struct cma_blk_s

/* Round up/down macros. */
#define ROUND_UP(x, align)	 (((int)(x) + (align - 1)) & ~(align - 1))
#define ROUND_DOWN(x, align) ((int) (x) & ~(align - 1))
#define ALIGNED(x, align)	 (((int)(x) & (align - 1)) == 0)


typedef int32_t Dtype;//origin data type
typedef int8_t INtype;
typedef int8_t Wtype;//weights data type



//fpga reg cnn
#if defined(ARCH_ABI_ARM64)
#define FPGAREG_CNN_BASE_ADDR				0x80000000
#define FPGAREG_MAP_SIZE						0x10000
#define FPGAREG_CNN_START						(0x00<<2)
#define FPGAREG_CNN_DDRIN						(0x04<<2)
#define FPGAREG_CNN_DDRW						(0x07<<2)
#define FPGAREG_CNN_DDROUT					(0x0A<<2)
#define FPGAREG_CNN_PARAM						(0x0D<<2)
#define FPGAREG_CNN_SCALE						(0x10<<2)
#elif defined(ARCH_ABI_ARM32)
#define FPGAREG_CNN_BASE_ADDR				0xFF200000
#define FPGAREG_MAP_SIZE						0x3FF
#define FPGAREG_CNN_START						(0x00<<4)
#define FPGAREG_CNN_DDRIN						(0x04<<4)
#define FPGAREG_CNN_DDRW						(0x07<<4)
#define FPGAREG_CNN_DDROUT					(0x0A<<4)
#define FPGAREG_CNN_PARAM						(0x0D<<4)
#define FPGAREG_CNN_SCALE						(0x10<<4)
#else
#define FPGAREG_CNN_BASE_ADDR				0x80000000
#define FPGAREG_MAP_SIZE						0x10000
#define FPGAREG_CNN_START						(0x00<<2)
#define FPGAREG_CNN_DDRIN						(0x04<<2)
#define FPGAREG_CNN_DDRW						(0x07<<2)
#define FPGAREG_CNN_DDROUT					(0x0A<<2)
#define FPGAREG_CNN_PARAM						(0x0D<<2)
#define FPGAREG_CNN_SCALE						(0x10<<2)
#endif


//reg reg reorgnaize
#if (REOGANIZE_TYPE == REOGANIZE_FPGA)
#if defined(ARCH_ABI_ARM64)
#define FPGAREG_REORG_BASE_ADDR			0x80010000
	#define FPGAREG_REORG_START				(0x00<<2)
	#if (FPGA_SOURCE == FPGA_SOURCE_NK)//海云重排直接给绝对地址就不需要这几个参数了
		#define FPGAREG_REORG_HD				(0x04<<2)
		#define FPGAREG_REORG_LD				(0x07<<2)
		#define FPGAREG_REORG_DATA			(0x13<<2)
	#endif
	#define FPGAREG_REORG_MODE				(0x0A<<2)
	#define FPGAREG_REORG_IN_C				(0x0C<<2)
	#define FPGAREG_REORG_FEATURE_MAP_SIZE		(0x0E<<2)
	#define FPGAREG_REORG_DDR_INPUT_OFFSET		(0x10<<2)
	#define FPGAREG_REORG_DDR_OUTPUT_OFFSET		(0x12<<2)
#elif defined(ARCH_ABI_ARM32)
#define FPGAREG_REORG_BASE_ADDR			0xFF208000
	#define FPGAREG_REORG_START				(0x00<<4)
	#if (FPGA_SOURCE == FPGA_SOURCE_NK)//海云重排直接给绝对地址就不需要这几个参数了
		#define FPGAREG_REORG_HD				(0x04<<4)
		#define FPGAREG_REORG_LD				(0x07<<4)
		#define FPGAREG_REORG_DATA			(0x13<<4)
	#endif
	#define FPGAREG_REORG_MODE				(0x0A<<4)
	#define FPGAREG_REORG_IN_C				(0x0C<<4)
	#define FPGAREG_REORG_FEATURE_MAP_SIZE		(0x0E<<4)
	#define FPGAREG_REORG_DDR_INPUT_OFFSET		(0x10<<4)
	#define FPGAREG_REORG_DDR_OUTPUT_OFFSET		(0x12<<4)
#else
#define FPGAREG_REORG_BASE_ADDR			0xFF208000
	#define FPGAREG_REORG_START				(0x00<<4)
	#if (FPGA_SOURCE == FPGA_SOURCE_NK)//海云重排直接给绝对地址就不需要这几个参数了
		#define FPGAREG_REORG_HD				(0x04<<4)
		#define FPGAREG_REORG_LD				(0x07<<4)
		#define FPGAREG_REORG_DATA			(0x13<<4)
	#endif
	#define FPGAREG_REORG_MODE				(0x0A<<4)
	#define FPGAREG_REORG_IN_C				(0x0C<<4)
	#define FPGAREG_REORG_FEATURE_MAP_SIZE		(0x0E<<4)
	#define FPGAREG_REORG_DDR_INPUT_OFFSET		(0x10<<4)
	#define FPGAREG_REORG_DDR_OUTPUT_OFFSET		(0x12<<4)
#endif

#endif

//fpga reg elementwise_add
#ifdef ARCH_ABI_ARM64
#define FPGAREG_ELEMENT_BASE_ADDR		0x80020000
#endif
#ifdef ARCH_ABI_ARM32
#define FPGAREG_ELEMENT_BASE_ADDR		0xFF200000
#endif
#if (FPGA_SOURCE == FPGA_SOURCE_NK)
#define FPGAREG_ELEMENT_START				0x00
#define FPGAREG_ELEMENT_DDRIN1			0x10
#define FPGAREG_ELEMENT_DDRIN2			0x1C
#define FPGAREG_ELEMENT_DDROUT			0x28
#define FPGAREG_ELEMENT_PARAM				0x34
#elif (FPGA_SOURCE == FPGA_SOURCE_AW)
#define FPGAREG_ELEMENT_START				(0x00<<2)
#define FPGAREG_ELEMENT_DDRIN1			(0x01<<2)
#define FPGAREG_ELEMENT_DDRIN2			(0x02<<2)
#define FPGAREG_ELEMENT_DDROUT			(0x03<<2)
#define FPGAREG_ELEMENT_PARAM				(0x04<<2)
#endif

//fpga data addr and size

// #define FPGADATA_CNN_INPUT_ADDR		0x10000000
// #define FPGADATA_CNN_INPUT_SIZE	  0x4000000
// #define FPGADATA_CNN_OUTPUT_ADDR		0x16000000
// #define FPGADATA_CNN_OUTPUT_SIZE	  0x4000000
#if defined(ARCH_ABI_ARM64)
#define FPGADATA_CNN_DATA_ADDR		    0x10000000
#define FPGADATA_CNN_DATA_SIZE	      0x30000000
#define FPGADATA_CNN_WEIGHT_ADDR			0x40000000
#define FPGADATA_CNN_WEIGHT_SIZE	    0x30000000
#define FPGADATA_CNN_PARAM_ADDR			  0x70000000
#define FPGADATA_CNN_PARAM_SIZE		    0x1000000
#define FPGADATA_CNN_SCALE_ADDR 			0x71000000
#define FPGADATA_CNN_SCALE_SIZE   		0x1000000

#define FPGADATA_ORGANIZE_DATA_ADDR		0x72000000
#define FPGADATA_ORGANIZE_DATA_SIZE   0x8000000
#elif defined(ARCH_ABI_ARM32)
#define FPGADATA_CNN_DATA_SIZE	      0x1000000
#define FPGADATA_CNN_WEIGHT_SIZE	    0x1000000
#define FPGADATA_CNN_PARAM_SIZE		    0x1000000
#define FPGADATA_CNN_SCALE_SIZE   		0x1000000
#define FPGADATA_ORGANIZE_DATA_SIZE   0x1000000
#else
#define FPGADATA_CNN_DATA_ADDR		    0x10000000
#define FPGADATA_CNN_DATA_SIZE	      0x30000000
#define FPGADATA_CNN_WEIGHT_ADDR			0x40000000
#define FPGADATA_CNN_WEIGHT_SIZE	    0x30000000
#define FPGADATA_CNN_PARAM_ADDR			  0x70000000
#define FPGADATA_CNN_PARAM_SIZE		    0x1000000
#define FPGADATA_CNN_SCALE_ADDR 			0x71000000
#define FPGADATA_CNN_SCALE_SIZE   		0x1000000

#define FPGADATA_ORGANIZE_DATA_ADDR		0x72000000
#define FPGADATA_ORGANIZE_DATA_SIZE   0x8000000
#endif



// #define FPGADATA_ELEADD_INPUT_SIZE		0x4000000
// #define FPGADATA_ELEADD_INPUT1_ADDR		0x81000000
// #define FPGADATA_ELEADD_INPUT2_ADDR		0x85000000
// #define FPGADATA_ELEADD_OUTPUT_SIZE		0x4000000
// #define FPGADATA_ELEADD_OUTPUT_ADDR		0x89000000

// #define FPGADATA_ELEADD_PARAM_ADDR		0x8D000000
// #define FPGADATA_ELEADD_PARAM_SIZE		0x1000000

/*quantification macro parameter*/
#define Q_MAX		127
#define Q_MIN		-127
#define W_MAX		127
#define W_MIN		-127

uint32_t* udata;
uint32_t* uorganize;
// uint32_t* add_uparam;
// uint32_t* input;
// uint32_t* output;
uint32_t* uweight;
uint32_t* uparam;
uint32_t* uscale;
uint32_t* foo;
#if (REOGANIZE_TYPE == REOGANIZE_FPGA)
uint32_t* data_reorganize_ip;
#endif
uint32_t* add_ip;







#endif
