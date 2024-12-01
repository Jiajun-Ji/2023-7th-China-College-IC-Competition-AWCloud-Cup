#ifndef _INTELFPGA_H_
#define _INTELFPGA_H_


#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <vector>
#include <string>

#define REOGANIZE_FPGA		0
#define REOGANIZE_ARM		1
#define REOGANIZE_TYPE		REOGANIZE_ARM // REOGANIZE_FPGA

#define ARMREOG_POLL		0
#define ARMREOG_NEON		1
#define ARMREOG_TYPE		ARMREOG_NEON // ARMREOG_NEON


/*convolutional layer macro parameter*/
#define ADD_INPUT_WIDTH 8
#define ADD_EXTEND_INPUT_WIDTH	32
#define ADD_INPUT_EXTEND_SCALE	(ADD_EXTEND_INPUT_WIDTH / ADD_INPUT_WIDTH)
#define INPUT_CHANNEL_TILE		8
#define INPUT_EXTEND_SCALE	INPUT_CHANNEL_TILE
#define EXTEND_INPUT_CHANNEL_TILE	(INPUT_CHANNEL_TILE/INPUT_EXTEND_SCALE)
#define OUTPUT_CHANNEL_TILE  	INPUT_CHANNEL_TILE
#define EXTEND_OUTPUT_CHANNEL_TILE	(OUTPUT_CHANNEL_TILE/INPUT_EXTEND_SCALE)
#define WEIGHT_EXTEND_SCALE	OUTPUT_CHANNEL_TILE
//hardware config

#define OUTPUT_ROW_TILE			5
#define INPUT_ROW_TILE			11

// #define OUTPUT_ROW_TILE			10
// #define INPUT_ROW_TILE			21
#define max_kernel				3
#define MAX_KERNEL_SIZE			(max_kernel*max_kernel)
#define image_h 			 302//610	
#define MAX_OUTPUT_W		 150//304	
#define image_w 				image_h
#define INPUT_BUFF_SIZE (INPUT_ROW_TILE*image_h)
#define OUTPUT_BUFF_SIZE (MAX_OUTPUT_W*OUTPUT_ROW_TILE)

// Activation type
#define INTELFPGA_ACT_NONE 0
#define INTELFPGA_ACT_RELU 1
#define INTELFPGA_ACT_RELU6 2
#define INTELFPGA_ACT_LEAKYRELU 3
//op type
#define INTELFPGA_Conv2D	1
#define INTELFPGA_DW_Conv2D	4
// #define INTELFPGA_CALIB	3
// #define INTELFPGA_Pool2D_MAX 5
// #define INTELFPGA_Pool2D_AVG 6
// #define INTELFPGA_ELE_ADD 7

enum class ElementWiseOpType:int {
  op_add = 1,
	op_concat = 2
};

struct parameter{
	int input_offset;
	int weight_offset;
	int scale_offset;
	int output_offset;

	int in_c;
	int in_h;
	int in_w;
	int output_c;
	int output_h;
	int output_w;
	int kernel;
	int in_pad;
	int out_pad;
	int stride;
	int relu;
	int type;//conv 1; dw_conv:4

	int output_channel_block_num;
	int output_row_tile;
	int input_row_tile;
	int output_row_block_num;

	float input_scale;
	float output_scale;

	float lr;
	int dilation;
	int weight_size;
	int input_size;
	int output_size;
};

struct device_weight_config{
	int weight_size;
	int weight_offset;
};
struct device_output_config{
	int output_size;
	int output_offset;
};

struct NodeParam {
	virtual ~NodeParam() = default;
  int node_id_{0};  
};

struct FpgaConvParam: public NodeParam {
	float             lr; // Leaky Relu alpha
	int8_t*            ia{nullptr}; // input address, [N,Ci,Hi,Wi]
	int8_t*            d_ia{nullptr}; // device input address, [N,Ci/INPUT_CHANNLE_TILE,Hi,Wi,INPUT_CHANNLE_TILE]
	int8_t*            ka{nullptr}; // kernel address, [Co,Ci,Hk,Wk]
	int8_t*            d_ka{nullptr}; // device kernel address, [Co/INPUT_CHANNLE_TILE,Ci,Hk,Wk,INPUT_CHANNLE_TILE]
	int8_t*            oa{nullptr}; // output address, [N,Co,Ho,Wo]
	int8_t*            d_oa{nullptr}; // output address, [N,Co/INPUT_CHANNLE_TILE,Ho,Wo/INPUT_CHANNLE_TILE]
	float *			   scale{nullptr}; // filter scale
	struct parameter param;
};



struct DeviceGraphNode {
	bool is_output{false};
	bool is_input{false};
	std::string name_;
	int op_type_;
	std::vector<DeviceGraphNode*> parent_vec_; // The op which it's input tensor belong to.
	struct DeviceGraphNode* next_{nullptr};  // Next op to be executed in topological order.
	struct NodeParam* node_param_{nullptr};
};

/* function declarations */
int up_round(int a, int b);
int intelfpga_subgraph(struct DeviceGraphNode* node); 
int fpga_init();
struct device_weight_config dw_conv2d_weight_reorganize(int8_t*src,int8_t**dst,int out_c,int kh,int kw);
struct device_weight_config conv2d_weight_reorganize(int8_t*src,int8_t**dst,int out_c,int in_c,int kh,int kw, const char* filter_name);
struct device_output_config intelfpga_output_malloc(int8_t**dst, int out_c, int out_h, int out_w);
void intelfpga_free(void *ptr);
void* intelfpga_malloc(size_t size);

struct device_output_config FpgaMemMalloc(int op_type,
                                         int8_t* dst,
                                         int c,
                                         int h,
                                         int w);
																				
int FpgaByte2WordOffset(int op_type, int byte_offset);
int FpgaWord2ByteOffset(int op_type, int word_offset);
int FpgaGetOutputOffset(DeviceGraphNode* node);

void fpga_release(void);

#endif
