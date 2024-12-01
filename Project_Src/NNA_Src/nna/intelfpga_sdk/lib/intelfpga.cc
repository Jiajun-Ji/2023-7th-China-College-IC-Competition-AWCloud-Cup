/* Copyright (c) 2020 AWCloud. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#include "intelfpga.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include <fstream>
#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <vector>
#include <chrono>

#include "common.h"
#include "arm_neon.h"

#include "omp.h"

using namespace std;

// #define PROFILE
#define SDK_EMULATE 0
#define SDK_ADD 0
#ifdef PROFILE
#define LOG_OUT 0
#endif
#define PRINT_DBG 0

// FD of mma
static int fpga_fd = -1;
//fpga init status
static bool fpga_init_status = false;
// Memory blocks
static int weight_offset = 0;
static int output_offset = 0;
//---------------------------------------------------------------------------
struct mem_cfg
{
  int8_t *src;
  int8_t *dst;
  int size;
  bool valid;
};
static struct mem_cfg global_mem_cfg;

char const *op_type[] = {
    "",
    "INTELFPGA_Conv2D",
    "",
    "INTELFPGA_CALIB",
    "INTELFPGA_DW_Conv2D",
    "INTELFPGA_Pool2D_MAX",
    "INTELFPGA_Pool2D_AVG",
    "INTELFPGA_ELE_ADD",
};

#if LOG_OUT
enum
{
  LOGOUT_CONV_IN,
  LOGOUT_CONV_OUT,
  LOGOUT_REGIN_IN,
  LOGOUT_REGIN_OUT,
  LOGOUT_REGOUT_IN,
  LOGOUT_REGOUT_OUT,
  LOGOUT_ELEADD_INPUT1,
  LOGOUT_ELEADD_INPUT2,
  LOGOUT_ELEADD_OUTPUT,
};

void PrintDeviceParam_log(parameter *param, int layer, FILE *fp)
{
  fprintf(fp, "---layer:%02d---\n", layer);
  fprintf(fp, "input_offset:%d\n", param->input_offset);
  fprintf(fp, "weight_offset:%d\n", param->weight_offset);
  // fprintf(fp,"scale_offset:%d\n",param->scale_offset);
  fprintf(fp, "output_offset:%d\n", param->output_offset);
  fprintf(fp, "in_c:%d\n", param->in_c);
  fprintf(fp, "in_h:%d\n", param->in_h);
  fprintf(fp, "in_w:%d\n", param->in_w);
  fprintf(fp, "output_c:%d\n", param->output_c);
  fprintf(fp, "output_h:%d\n", param->output_h);
  fprintf(fp, "output_w:%d\n", param->output_w);
  fprintf(fp, "kernel:%d\n", param->kernel);
  fprintf(fp, "in_pad:%d\n", param->in_pad);
  fprintf(fp, "out_pad:%d\n", param->out_pad);
  fprintf(fp, "stride:%d\n", param->stride);
  fprintf(fp, "relu:%d\n", param->relu);
  fprintf(fp, "type:%d\n", param->type);

  fprintf(fp, "input_scale:%f\n", param->input_scale);
  fprintf(fp, "output_scale:%f\n", param->output_scale);

  fprintf(fp, "lr:%f\n", param->lr);
  fprintf(fp, "dilation:%d\n", param->dilation);
  fprintf(fp, "weight_size:%d\n", param->weight_size);
  fprintf(fp, "input_size:%d\n", param->input_size);
  fprintf(fp, "output_size:%d\n", param->output_size);

  fprintf(fp, "output_channel_block_num:%d\n", param->output_channel_block_num);
  fprintf(fp, "output_row_tile:%d\n", param->output_row_tile);
  fprintf(fp, "input_row_tile:%d\n", param->input_row_tile);
  fprintf(fp, "output_row_block_num:%d\n", param->output_row_block_num);
}

void PrintAddParam_log(AddParameter *param, int layer, FILE *fp)
{
  fprintf(fp, "---layer:%02d---\n", layer);
  fprintf(fp, "input1_offset:%d\n", param->input1_offset);
  fprintf(fp, "input2_offset:%d\n", param->input2_offset);
  fprintf(fp, "output_offset:%d\n", param->output_offset);
  fprintf(fp, "input1_c:%d\n", param->input1_c);
  fprintf(fp, "input1_h:%d\n", param->input1_h);
  fprintf(fp, "input1_w:%d\n", param->input1_w);
  fprintf(fp, "input2_c:%d\n", param->input2_c);
  fprintf(fp, "input2_h:%d\n", param->input2_h);
  fprintf(fp, "input2_w:%d\n", param->input2_w);
  fprintf(fp, "output_c:%d\n", param->output_c);
  fprintf(fp, "output_h:%d\n", param->output_h);
  fprintf(fp, "output_w:%d\n", param->output_w);
  fprintf(fp, "input1_scale:%f\n", param->input1_scale);
  fprintf(fp, "input2_scale:%f\n", param->input2_scale);
  fprintf(fp, "output_scale:%f\n", param->output_scale);
  fprintf(fp, "type:%d\n", param->type);
  fprintf(fp, "relu:%d\n", param->relu);
}

void log_to_file(NodeParam *node_param, uint8_t layer, uint8_t type, uint8_t *data, size_t size, uint8_t datacount_of_line)
{
  char file_name[64];
  FILE *fp = NULL;

  switch (type)
  {
  case LOGOUT_CONV_IN:
    sprintf(file_name, "./log/layer%02d-conv-in.txt", layer);
    break;
  case LOGOUT_CONV_OUT:
    sprintf(file_name, "./log/layer%02d-conv-out.txt", layer);
    break;
  case LOGOUT_REGIN_IN: // reg_in
    sprintf(file_name, "./log/layer%02d-reog-in-in.txt", layer);
    break;
  case LOGOUT_REGIN_OUT:
    sprintf(file_name, "./log/layer%02d-reog-in-out.txt", layer);
    break;
  case LOGOUT_REGOUT_IN:
    sprintf(file_name, "./log/layer%02d-reog-out-in.txt", layer);
    break;
  case LOGOUT_REGOUT_OUT: // reg_out
    sprintf(file_name, "./log/layer%02d-reog-out-out.txt", layer);
    break;
  case LOGOUT_ELEADD_INPUT1: //
    sprintf(file_name, "./log/layer%02d-eleadd-input1.txt", layer);
    break;
  case LOGOUT_ELEADD_INPUT2:
    sprintf(file_name, "./log/layer%02d-eleadd-input2.txt", layer);
    break;
  case LOGOUT_ELEADD_OUTPUT:
    sprintf(file_name, "./log/layer%02d-eleadd-output.txt", layer);
    break;
  }

  fp = fopen(file_name, "w+");

  if (type < LOGOUT_ELEADD_INPUT1)
  {
    auto conv_param = dynamic_cast<FpgaConvParam *>(node_param);
    PrintDeviceParam_log(&conv_param->param, layer, fp);
  }
  else
  {
    auto ele_param = dynamic_cast<FpgaElementwiseParam *>(node_param);
    PrintAddParam_log(&ele_param->add_param, layer, fp);
  }

  for (size_t i = 0; i < size; i++)
  {
    if (i % datacount_of_line == 0)
      fprintf(fp, "\r\n");
    fprintf(fp, "%02X", data[i]);
  }
  fclose(fp);
}
#endif

/**
 * @brief
 *
 * @param fd
 * @param pcb
 * @return int
 */
int cma_alloc(int fd, struct cma_blk_s *pcb)
{
  pcb->size = ROUND_UP(pcb->size, sysconf(_SC_PAGE_SIZE));
  if (ioctl(fd, CMA_IOCTL_MAKE(CMA_CMD_ALLOC), pcb))
  {
    printf("CMA_CMD_ALLOC failed\n");
    return -1;
  }
  /* Map to user-land address space */
  pcb->addr = mmap(0, pcb->size,
                   PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED,
                   fd, pcb->phys);
  if (pcb->addr == MAP_FAILED)
  {
    ioctl(fd, CMA_IOCTL_MAKE(CMA_CMD_FREE), pcb);
    return -1;
  }
  return 0;
}

/**
 * @brief
 *
 * @param fd
 * @param pcb
 * @return int
 */
int cma_free(int fd, struct cma_blk_s *pcb)
{
  if (munmap(pcb->addr, pcb->size) == -1)
    return -1;
  if (ioctl(fd, CMA_IOCTL_MAKE(CMA_CMD_FREE), pcb))
  {
    printf("CMEM_CMD_FREE failed\n");
    return -1;
  }
  return 0;
}

/**
 * @brief
 *
 * @param param
 * @param layer
 * @param type
 */
void PrintDeviceParam(struct DeviceGraphNode *node, int layer)
{
  auto param = &(dynamic_cast<FpgaConvParam *>(node->node_param_)->param);
  std::cout << "\n---layer: " << layer << "->conv---"
            << "\n";
  if (node->is_input)
    std::cout << "success input reorg"
              << "\n";
  if (node->is_output)
    std::cout << "success output reorg"
              << "\n";
  std::cout << "op type:" << op_type[node->op_type_] << "\n";

  std::cout << "input_offset: " << param->input_offset << "\n";
  std::cout << "weight_offset: " << param->weight_offset << "\n";
  std::cout << "scale_offset: " << param->scale_offset << "\n";
  std::cout << "output_offset: " << param->output_offset << "\n";
  std::cout << "in_c: " << param->in_c << "\n";
  std::cout << "in_h: " << param->in_h << "\n";
  std::cout << "in_w: " << param->in_w << "\n";
  std::cout << "output_c: " << param->output_c << "\n";
  std::cout << "output_h: " << param->output_h << "\n";
  std::cout << "output_w: " << param->output_w << "\n";
  std::cout << "kernel: " << param->kernel << "\n";
  std::cout << "in_pad: " << param->in_pad << "\n";
  std::cout << "out_pad: " << param->out_pad << "\n";
  std::cout << "stride: " << param->stride << "\n";
  std::cout << "relu: " << param->relu << "\n";
  std::cout << "type: " << param->type << "\n";

  std::cout << "input_scale: " << param->input_scale << "\n";
  std::cout << "output_scale: " << param->output_scale << "\n";

  std::cout << "lr: " << param->lr << "\n";
  std::cout << "dilation: " << param->dilation << "\n";
  // std::cout << "weight_size: " << param->weight_size << "\n";
  // std::cout << "input_size: " << param->input_size << "\n";
  // std::cout << "output_size: " << param->output_size << "\n";

  std::cout << "output_channel_block_num: " << param->output_channel_block_num << "\n";
  std::cout << "output_row_tile: " << param->output_row_tile << "\n";
  std::cout << "input_row_tile: " << param->input_row_tile << "\n";
  std::cout << "output_row_block_num: " << param->output_row_block_num << "\n";
}


/**
 * @brief
 *
 * @param a
 * @param b
 * @return int
 */
int up_round(int a, int b)
{
  return (a - 1) / b + 1;
}

/**
 * @brief
 *
 * @param ptr
 */
void intelfpga_free(void *ptr)
{
  free(ptr);
}

/**
 * @brief
 *
 * @param size
 * @return void*
 */
void *intelfpga_malloc(size_t size)
{
  return malloc(size);
}

/**
 * @brief
 *
 * @param fd
 * @param addr
 * @param length
 * @param offset
 */
void memorymap(int fd, uint32_t **addr, size_t length, off_t offset)
{
  *addr = (uint32_t *)mmap(0, length, PROT_READ | PROT_WRITE,
                           MAP_SHARED, fd, offset);
  if (*addr == (void *)-1)
  {
    printf("Can't map the memory:%lX to user space.\n", offset);
    fpga_release();
    exit(-1);
  }
  // memset(addr, 0, length);
}

void memoryunmap(void *addr, size_t len)
{
  if (munmap(addr, len) == -1)
  {
    printf("memmory unmap failed\n");
  }
}

/**
 * @brief
 *
 * @param addr
 * @param offset
 * @param value
 */
void foo_set(uint32_t *addr, int offset, uint32_t value)
{
  //*((volatile unsigned long *) (addr+offset /4)) = value;
  addr[offset >> 2] = value;
}

/**
 * @brief
 *
 * @param addr
 * @param offset
 * @return uint32_t
 */
uint32_t foo_get(uint32_t *addr, int offset)
{
  return addr[offset >> 2];
}

/**
 * @brief
 *
 * @param v
 * @param max
 * @param min
 * @return int
 */
int clip(int v, int max, int min)
{
  if (v > max)
    return max;
  if (v < min)
    return min;
  return v;
}

/**
 * @brief
 *
 * @param a
 * @return int
 */
int myround(float a)
{
  int b;
  b = a;
  if (a - b > 0 && a - b >= 0.5)
    b++;
  if (a - b < 0 && a - b < -0.5)
    b--;
  return b;
}

/**
 * @brief
 *
 * @param x
 * @return INtype
 */
static INtype quantize(float x)
{
  int sign, exp, mag;
  int y = 0;
  unsigned int x_int_expr = *(int *)&x;
  sign = x_int_expr >> 31;
  exp = ((x_int_expr & 0x7f800000) >> 23);
  mag = (x_int_expr & 0x7fffff);
  // NON number.
  if (exp == 126)
  {
    // INF or NaN.
    y = 1;
  }
  else if (exp < 126)
  {
    // Subnormal number.
    y = 0;
  }
  else
  {
    exp = exp - 127;
    mag = mag >> (23 - exp - 1);
    if ((mag & 0x1) == 1)
    {
      y = y + 1;
    }
    y += (1 << exp) | (mag >> 1);
  }

  if (sign == 1)
  {
    y = -y;
  }
  if (y > Q_MAX)
    return Q_MAX;
  if (y < Q_MIN)
    return Q_MIN;
  return y;
}

/**
 * @brief
 *
 * @param a
 * @param b
 * @return int
 */
int min(int a, int b)
{
  return a > b ? b : a;
}

/**
 * @brief
 *
 * @param fd
 * @param cb
 * @param data_addr
 */
void fpga_data_address_cmamap(int fd, struct cma_blk_s *cb, uint32_t **data_addr)
{
  if (cma_alloc(fd, cb))
  {
    close(fd);
    printf("cma_alloc fail!\n");
    exit(-1);
  }
  *data_addr = (uint32_t *)cb->addr;
}


/**
 * @brief
 *
 * @param fd
 */
void fpga_reg_address_map(int fd)
{
  memorymap(fd, &foo, FPGAREG_MAP_SIZE, FPGAREG_CNN_BASE_ADDR);
#if (REOGANIZE_TYPE == REOGANIZE_FPGA)
  memorymap(fd, &data_reorganize_ip, FPGAREG_MAP_SIZE, FPGAREG_REORG_BASE_ADDR);
#endif
}

int devmem_fd = 0;
#ifdef ARCH_ABI_ARM32
int devcma_fd = 0;
cma_blk_s cb_data, cb_weight, cb_scale, cb_param, cb_org;
#endif

void fpga_release(void)
{
  if(fpga_init_status){

  printf("fpga release\n");
  cma_free(devcma_fd, &cb_data);
  cma_free(devcma_fd, &cb_weight);
  cma_free(devcma_fd, &cb_scale);
  cma_free(devcma_fd, &cb_param);
  cma_free(devcma_fd, &cb_org);
  close(devcma_fd);

  memoryunmap((uint32_t *)foo, FPGAREG_MAP_SIZE);
  close(devmem_fd);
  }

  output_offset = 0;
  weight_offset = 0;
}

int fpga_init()
{
  if (fpga_init_status)
  {
    return 0;
  }
#if PRINT_DBG
  printf("\r\n-------------fpga init--------------\r\n");
  printf("fpga reg conv base addr:%X\n", FPGAREG_CNN_BASE_ADDR);
#endif
  devmem_fd = open("/dev/mem", O_RDWR | O_SYNC);
  fpga_reg_address_map(devmem_fd);

  devcma_fd = open("/dev/cmadrv0", O_RDWR);
  if (devcma_fd < 0)
  {
    printf("open drvier failed\n");
    fpga_release();
    exit(-1);
  }
  // cma_blk_s cb_data,cb_weight,cb_scale,cb_param,cb_org;
  cb_data.size = FPGADATA_CNN_DATA_SIZE;
  cb_weight.size = FPGADATA_CNN_WEIGHT_SIZE;
  cb_param.size = FPGADATA_CNN_PARAM_SIZE;
  cb_scale.size = FPGADATA_CNN_SCALE_SIZE;
  cb_org.size = FPGADATA_ORGANIZE_DATA_SIZE;

  fpga_data_address_cmamap(devcma_fd, &cb_data, &udata);
  fpga_data_address_cmamap(devcma_fd, &cb_weight, &uweight);
  fpga_data_address_cmamap(devcma_fd, &cb_param, &uparam);
  fpga_data_address_cmamap(devcma_fd, &cb_scale, &uscale);
  fpga_data_address_cmamap(devcma_fd, &cb_org, &uorganize);

  printf("cb_data.phy:%x\r\n", cb_data.phys);
  printf("cb_weight.phy:%x\r\n", cb_weight.phys);
  printf("cb_param.phy:%x\r\n", cb_param.phys);
  printf("cb_scale.phy:%x\r\n", cb_scale.phys);
  printf("cb_org.phy:%x\r\n", cb_org.phys);

  foo_set(foo, FPGAREG_CNN_DDROUT, cb_data.phys);
  foo_set(foo, FPGAREG_CNN_DDRIN, cb_data.phys);
  foo_set(foo, FPGAREG_CNN_DDRW, cb_weight.phys);
  foo_set(foo, FPGAREG_CNN_PARAM, cb_param.phys);
  foo_set(foo, FPGAREG_CNN_SCALE, cb_scale.phys);



  fpga_init_status = true;
  return 0;
}

int start_fpga(uint32_t *ip, uint32_t start_reg_addr)
{
  uint32_t status;
  status = foo_get(ip, start_reg_addr);
  status |= 0x1;
  foo_set(ip, start_reg_addr, status);
  // if(ip == foo)
  // {
  //   if (global_mem_cfg.valid)
  //   {
  //     memcpy(global_mem_cfg.dst, global_mem_cfg.src, global_mem_cfg.size);
  //     global_mem_cfg.valid = false;
  //   }
  // }
  status = foo_get(ip, start_reg_addr);
#if PRINT_DBG
  printf("get status:%d\n", status);
#endif
  auto waitip_start = std::chrono::steady_clock::now();

  while (status & 1)

  {
    // usleep(1);
    status = foo_get(ip, start_reg_addr);
    std::chrono::duration<float> wait_ip_time = std::chrono::steady_clock::now() - waitip_start;
    if (wait_ip_time.count() >= 5)
    {
      printf("wait ip fail.\n");
      fpga_release();
      exit(-1);
    }
  }
#if PRINT_DBG
  printf("fpga over:%d\n", status);
#endif
}

#if (REOGANIZE_TYPE == REOGANIZE_FPGA)
void data_reorganize(int mode, int in_c, int feature_map, int input_offset, int output_offset)
{
  foo_set(data_reorganize_ip, FPGAREG_REORG_MODE, mode);
  foo_set(data_reorganize_ip, FPGAREG_REORG_IN_C, in_c);
  foo_set(data_reorganize_ip, FPGAREG_REORG_FEATURE_MAP_SIZE, feature_map);
  foo_set(data_reorganize_ip, FPGAREG_REORG_DDR_INPUT_OFFSET, input_offset);
  foo_set(data_reorganize_ip, FPGAREG_REORG_DDR_OUTPUT_OFFSET, output_offset);

  int32_t status;
  status = foo_get(data_reorganize_ip, FPGAREG_REORG_START);
  status |= 0x1;
  foo_set(data_reorganize_ip, FPGAREG_REORG_START, status);
  status = foo_get(data_reorganize_ip, FPGAREG_REORG_START);

  while (status & 1)
  {

    status = foo_get(data_reorganize_ip, FPGAREG_REORG_START);
  }
}

#elif (REOGANIZE_TYPE == REOGANIZE_ARM)
#if (ARMREOG_TYPE == ARMREOG_NEON)
void tran_8(uint8_t *gbild_, uint8_t *gbild_t_, size_t gx, size_t gy)
{
  // 2D-var für originales und getransponiertes Bild
  uint8_t **gbild = (uint8_t **)malloc(sizeof(char *) * gy);
  uint8_t **gbild_t = (uint8_t **)malloc(sizeof(char *) * gx);
  // #pragma unroll(32)
  for (int i = 0; i < gy; i++)
  {
    gbild[i] = gbild_ + i * gx;
  }
  // #pragma unroll(32)
  for (int i = 0; i < gx; i++)
  {
    gbild_t[i] = gbild_t_ + i * gy;
  }

  // Neon-Register definieren
  uint8x8x2_t reg882_0, reg882_1, reg882_2, reg882_3;
  uint16x4x2_t reg1642_0, reg1642_1, reg1642_2, reg1642_3;
  uint32x2x2_t reg3222_0, reg3222_1, reg3222_2, reg3222_3;
  int gx_r = gx % 8;
  int gy_r = gy % 8;
  int gx_l = gx - 7;
  int gy_l = gy - 7;
  int gx_k = gx - gx_r;
  int gy_k = gy - gy_r;
  int x, y;

  for (y = 0; y < gy_l; y += 8)
  {
    #pragma unroll(32)
    for (x = 0; x < gx_l; x += 8)
    {
      // laden 8 Reihen Daten
      reg882_0.val[0] = vld1_u8(&gbild[y][x]);
      reg882_0.val[1] = vld1_u8(&gbild[y + 1][x]);
      reg882_1.val[0] = vld1_u8(&gbild[y + 2][x]);
      reg882_1.val[1] = vld1_u8(&gbild[y + 3][x]);
      reg882_2.val[0] = vld1_u8(&gbild[y + 4][x]);
      reg882_2.val[1] = vld1_u8(&gbild[y + 5][x]);
      reg882_3.val[0] = vld1_u8(&gbild[y + 6][x]);
      reg882_3.val[1] = vld1_u8(&gbild[y + 7][x]);

      // je 2 Reihen transponieren
      reg882_0 = vtrn_u8(reg882_0.val[0], reg882_0.val[1]);
      reg882_1 = vtrn_u8(reg882_1.val[0], reg882_1.val[1]);
      reg882_2 = vtrn_u8(reg882_2.val[0], reg882_2.val[1]);
      reg882_3 = vtrn_u8(reg882_3.val[0], reg882_3.val[1]);

      // 8-bit-tief -> 16-bit-tief, dann 1 und 3 Reihe, 2 und 4 Reihen, 5 und 7
      // Reihen, 6 und 8 Reihen transponieren
      reg1642_0 = vtrn_u16(vreinterpret_u16_u8(reg882_0.val[0]),
                           vreinterpret_u16_u8(reg882_1.val[0]));
      reg1642_1 = vtrn_u16(vreinterpret_u16_u8(reg882_0.val[1]),
                           vreinterpret_u16_u8(reg882_1.val[1]));
      reg1642_2 = vtrn_u16(vreinterpret_u16_u8(reg882_2.val[0]),
                           vreinterpret_u16_u8(reg882_3.val[0]));
      reg1642_3 = vtrn_u16(vreinterpret_u16_u8(reg882_2.val[1]),
                           vreinterpret_u16_u8(reg882_3.val[1]));

      // 16-bit-tief -> 32-bit-tief, dann 1 und 5 Reihen, 2 und 6 Reihen, 3 und
      // 7 Reihen, 4 und 8 Reihen transpinieren
      reg3222_0 = vtrn_u32(vreinterpret_u32_u16(reg1642_0.val[0]),
                           vreinterpret_u32_u16(reg1642_2.val[0]));
      reg3222_1 = vtrn_u32(vreinterpret_u32_u16(reg1642_0.val[1]),
                           vreinterpret_u32_u16(reg1642_2.val[1]));
      reg3222_2 = vtrn_u32(vreinterpret_u32_u16(reg1642_1.val[0]),
                           vreinterpret_u32_u16(reg1642_3.val[0]));
      reg3222_3 = vtrn_u32(vreinterpret_u32_u16(reg1642_1.val[1]),
                           vreinterpret_u32_u16(reg1642_3.val[1]));

      // 32-bit-tief -> 8-bit-tief
      reg882_0.val[0] = vreinterpret_u8_u32(reg3222_0.val[0]);
      reg882_0.val[1] = vreinterpret_u8_u32(reg3222_0.val[1]);
      reg882_1.val[0] = vreinterpret_u8_u32(reg3222_1.val[0]);
      reg882_1.val[1] = vreinterpret_u8_u32(reg3222_1.val[1]);
      reg882_2.val[0] = vreinterpret_u8_u32(reg3222_2.val[0]);
      reg882_2.val[1] = vreinterpret_u8_u32(reg3222_2.val[1]);
      reg882_3.val[0] = vreinterpret_u8_u32(reg3222_3.val[0]);
      reg882_3.val[1] = vreinterpret_u8_u32(reg3222_3.val[1]);

      // store
      vst1_u8(&gbild_t[x][y], reg882_0.val[0]);
      vst1_u8(&gbild_t[x + 1][y], reg882_2.val[0]);
      vst1_u8(&gbild_t[x + 2][y], reg882_1.val[0]);
      vst1_u8(&gbild_t[x + 3][y], reg882_3.val[0]);
      vst1_u8(&gbild_t[x + 4][y], reg882_0.val[1]);
      vst1_u8(&gbild_t[x + 5][y], reg882_2.val[1]);
      vst1_u8(&gbild_t[x + 6][y], reg882_1.val[1]);
      vst1_u8(&gbild_t[x + 7][y], reg882_3.val[1]);
    }
  }

  // Rest transponieren
  for (y = gy_k; y < gy; y++)
  {
    for (x = 0; x < gx; x++)
    {
      gbild_t[x][y] = gbild[y][x];
    }
  }
  for (x = gx_k; x < gx; x++)
  {
    for (y = 0; y < gy_k; y++)
    {
      gbild_t[x][y] = gbild[y][x];
    }
  }
  free(gbild);
  free(gbild_t);
}
//input
void tran_8_1(uint8_t *gbild_, uint8_t *gbild_t_, size_t gx, size_t gy)
{
  omp_set_num_threads(2);
    // 2D-var für originales und getransponiertes Bild
    uint8_t **gbild = (uint8_t **)malloc(sizeof(char *) * gy);
    uint8_t **gbild_t = (uint8_t **)malloc(sizeof(char *) * gx);
  #pragma unroll(32)
    for (int i = 0; i < gy; i++)
    {
        gbild[i] = gbild_ + i * gx;
    }
  #pragma unroll(32)
    for (int i = 0; i < gx; i++)
    {
        gbild_t[i] = gbild_t_ + i * gy;
    }

    // Neon-Register definieren
    uint8x8x2_t reg882_0, reg882_1, reg882_2, reg882_3;
    uint16x4x2_t reg1642_0, reg1642_1, reg1642_2, reg1642_3;
    uint32x2x2_t reg3222_0, reg3222_1, reg3222_2, reg3222_3;
    int gx_r = gx % 8;
    int gy_r = gy % 8;
    int gx_l = gx - 7;
    int gy_l = gy - 7;
    int gx_k = gx - gx_r;
    int gy_k = gy - gy_r;
    int x, y;
// #pragma unroll(32)
    for (y = 0; y < gy_l; y += 8)
    {
      #pragma unroll(32)
      // #pragma omp parallel for
        for (x = 0; x < gx_l; x += 8)
        {
            // laden 8 Reihen Daten
            reg882_0.val[0] = vld1_u8(&gbild[y][x]);
            reg882_0.val[1] = vld1_u8(&gbild[y + 1][x]);
            reg882_1.val[0] = vld1_u8(&gbild[y + 2][x]);
            reg882_1.val[1] = vld1_u8(&gbild[y + 3][x]);
            reg882_2.val[0] = vld1_u8(&gbild[y + 4][x]);
            reg882_2.val[1] = vld1_u8(&gbild[y + 5][x]);
            reg882_3.val[0] = vld1_u8(&gbild[y + 6][x]);
            reg882_3.val[1] = vld1_u8(&gbild[y + 7][x]);

            // je 2 Reihen transponieren
            reg882_0 = vtrn_u8(reg882_0.val[0], reg882_0.val[1]);
            reg882_1 = vtrn_u8(reg882_1.val[0], reg882_1.val[1]);
            reg882_2 = vtrn_u8(reg882_2.val[0], reg882_2.val[1]);
            reg882_3 = vtrn_u8(reg882_3.val[0], reg882_3.val[1]);

            // 8-bit-tief -> 16-bit-tief, dann 1 und 3 Reihe, 2 und 4 Reihen, 5 und 7
            // Reihen, 6 und 8 Reihen transponieren
            reg1642_0 = vtrn_u16(vreinterpret_u16_u8(reg882_0.val[0]),
                                 vreinterpret_u16_u8(reg882_1.val[0]));
            reg1642_1 = vtrn_u16(vreinterpret_u16_u8(reg882_0.val[1]),
                                 vreinterpret_u16_u8(reg882_1.val[1]));
            reg1642_2 = vtrn_u16(vreinterpret_u16_u8(reg882_2.val[0]),
                                 vreinterpret_u16_u8(reg882_3.val[0]));
            reg1642_3 = vtrn_u16(vreinterpret_u16_u8(reg882_2.val[1]),
                                 vreinterpret_u16_u8(reg882_3.val[1]));

            // 16-bit-tief -> 32-bit-tief, dann 1 und 5 Reihen, 2 und 6 Reihen, 3 und
            // 7 Reihen, 4 und 8 Reihen transpinieren
            reg3222_0 = vtrn_u32(vreinterpret_u32_u16(reg1642_0.val[0]),
                                 vreinterpret_u32_u16(reg1642_2.val[0]));
            reg3222_1 = vtrn_u32(vreinterpret_u32_u16(reg1642_0.val[1]),
                                 vreinterpret_u32_u16(reg1642_2.val[1]));
            reg3222_2 = vtrn_u32(vreinterpret_u32_u16(reg1642_1.val[0]),
                                 vreinterpret_u32_u16(reg1642_3.val[0]));
            reg3222_3 = vtrn_u32(vreinterpret_u32_u16(reg1642_1.val[1]),
                                 vreinterpret_u32_u16(reg1642_3.val[1]));

            // 32-bit-tief -> 8-bit-tief
            // reg882_0.val[0] = vreinterpret_u8_u32(reg3222_0.val[0]);
            // reg882_0.val[1] = vreinterpret_u8_u32(reg3222_0.val[1]);
            // reg882_1.val[0] = vreinterpret_u8_u32(reg3222_1.val[0]);
            // reg882_1.val[1] = vreinterpret_u8_u32(reg3222_1.val[1]);
            // reg882_2.val[0] = vreinterpret_u8_u32(reg3222_2.val[0]);
            // reg882_2.val[1] = vreinterpret_u8_u32(reg3222_2.val[1]);
            // reg882_3.val[0] = vreinterpret_u8_u32(reg3222_3.val[0]);
            // reg882_3.val[1] = vreinterpret_u8_u32(reg3222_3.val[1]);

            // store
            vst1_u8(&gbild_t[x][y], vreinterpret_u8_u32(reg3222_0.val[0]));
            vst1_u8(&gbild_t[x + 1][y], vreinterpret_u8_u32(reg3222_2.val[0]));
            vst1_u8(&gbild_t[x + 2][y], vreinterpret_u8_u32(reg3222_1.val[0]));
            vst1_u8(&gbild_t[x + 3][y], vreinterpret_u8_u32(reg3222_3.val[0]));
            vst1_u8(&gbild_t[x + 4][y], vreinterpret_u8_u32(reg3222_0.val[1]));
            vst1_u8(&gbild_t[x + 5][y], vreinterpret_u8_u32(reg3222_2.val[1]));
            vst1_u8(&gbild_t[x + 6][y], vreinterpret_u8_u32(reg3222_1.val[1]));
            vst1_u8(&gbild_t[x + 7][y], vreinterpret_u8_u32(reg3222_3.val[1]));
        }
    }

    // Rest transponieren
    for (y = gy_k; y < gy; y++)
    {
        for (x = 0; x < gx; x++)
        {
            gbild_t[x][y] = gbild[y][x];
        }
    }
    for (x = gx_k; x < gx; x++)
    {
        for (y = 0; y < gy_k; y++)
        {
            gbild_t[x][y] = gbild[y][x];
        }
    }
    free(gbild);
    free(gbild_t);
}

#endif
void InputRearrange(int8_t *din,
                    int8_t *dout,
                    const int c,
                    const int h,
                    const int w,
                    const int pad)
{
#if (ARMREOG_TYPE == ARMREOG_POLL)
  int8_t *dout_array[INPUT_EXTEND_SCALE];

  int idx_fpga_idata = 0;
  for (int i = 0; i < up_round(c, INPUT_EXTEND_SCALE); i++)
  {
    dout_array[0] = din + i * ((h + 2 * pad) * (w + 2 * pad) * INPUT_EXTEND_SCALE);
    for (int n = 1; n < INPUT_EXTEND_SCALE; n++)
    {
      dout_array[n] = dout_array[n - 1] + (h + 2 * pad) * (w + 2 * pad);
    }
    for (int r = 0; r < (h + 2 * pad); r++)
    {
      for (int cc = 0; cc < (w + 2 * pad); cc++)
      {
        for (int k = 0; k < INPUT_EXTEND_SCALE; k++)
        {
          if (k < c)
            dout[idx_fpga_idata++] = *(dout_array[k]++); //*(dout_array[k] + r * w + cc);  //
          else
            dout[idx_fpga_idata++] = 0;
        }
      }
    }
  }
#elif (ARMREOG_TYPE == ARMREOG_NEON)
  int high = h + 2 * pad;
  int width = w + 2 * pad;
  int area = high * width;
  // int channel_count = up_round(c, INPUT_EXTEND_SCALE) * INPUT_EXTEND_SCALE;

  tran_8_1((uint8_t *)din, (uint8_t *)dout, area, up_round(c, INPUT_EXTEND_SCALE) * INPUT_EXTEND_SCALE);
  // tran_8((uint8_t *)din,(uint8_t *)dout,area,c);

  // for (int cc = 0; cc < area; cc++)
  // {
  //   memset(dout + cc * INPUT_EXTEND_SCALE + c, 0, INPUT_EXTEND_SCALE - c);
  // }

#endif
}

void OutputRearrange(
    int8_t *din, int8_t *dout, const int c, const int h, const int w)
{
#if (ARMREOG_TYPE == ARMREOG_POLL)
  int8_t *dout_array[INPUT_EXTEND_SCALE];
  int idx_fpga_idata = 0;
  for (int i = 0; i < up_round(c, INPUT_EXTEND_SCALE); i++)
  {
    dout_array[0] = dout + i * h * w * INPUT_EXTEND_SCALE;
    for (int n = 1; n < INPUT_EXTEND_SCALE; n++)
    {
      dout_array[n] = dout_array[n - 1] + h * w;
    }
    for (int r = 0; r < h; r++)
    {
      for (int cc = 0; cc < w; cc++)
      {
        for (int k = 0; k < INPUT_EXTEND_SCALE; k++)
        {
          *(dout_array[k]++) = din[idx_fpga_idata++];
        }
      }
    }
  }
#elif (ARMREOG_TYPE == ARMREOG_NEON)
  int area = h * w;
  #pragma omp parallel for
  #pragma unroll(32)
  for (int i = 0; i < up_round(c, INPUT_EXTEND_SCALE); i++)
  {
    tran_8((uint8_t *)din + i * area * INPUT_EXTEND_SCALE, (uint8_t *)dout + i * area * INPUT_EXTEND_SCALE, INPUT_EXTEND_SCALE, area);
  }

#endif
}
#endif

void input_reorganized(int8_t *src, int8_t *dst, int in_c, int in_h, int in_w)
{
  int input_c = up_round(in_c, INPUT_EXTEND_SCALE);
  for (int i = 0; i < input_c; i++)
  {
    for (int r = 0; r < in_h; r++)
    {
      for (int c = 0; c < in_w; c++)
      {
        for (int k = 0; k < INPUT_EXTEND_SCALE; k++)
        {
          if (i * INPUT_EXTEND_SCALE + k < in_c)
          {
            int8_t temp =
                src[((i * INPUT_EXTEND_SCALE + k) * in_h + r) * in_w + c];
            dst[((i * in_h + r) * in_w + c) * INPUT_EXTEND_SCALE + k] = temp;
          }
          else
          {
            dst[((i * in_h + r) * in_w + c) * INPUT_EXTEND_SCALE + k] = 0;
          }
        }
      }
    }
  }
}

void output_reorganize(
    int8_t *src, int8_t *dst, int out_c, int out_h, int out_w)
{
  int output_channel_block = (out_c - 1) / INPUT_EXTEND_SCALE + 1;
  for (int i = 0; i < output_channel_block; i++)
  {
    for (int r = 0; r < out_h; r++)
    {
      for (int c = 0; c < out_w; c++)
      {
        for (int k = 0; k < INPUT_EXTEND_SCALE; k++)
        {
          if (i * INPUT_EXTEND_SCALE + k < out_c)
          {
            int sw_index =
                (i * INPUT_EXTEND_SCALE + k) * out_h * out_w + r * out_w + c;
            int hw_index =
                ((i * out_h + r) * out_w + c) * INPUT_EXTEND_SCALE + k;
            dst[sw_index] = src[hw_index];
          }
        }
      }
    }
  }
}

// memory management;
struct device_output_config intelfpga_calib_output_malloc(int8_t **dst,
                                                          int out_c,
                                                          int out_h,
                                                          int out_w)
{
  fpga_init();
  int output_channel_block = (out_c - 1) / INPUT_EXTEND_SCALE + 1;
  int output_size = output_channel_block * INPUT_CHANNEL_TILE * out_h * out_w;
  if (*dst == nullptr)
  {
    *dst = (int8_t *)udata + output_offset;
  }
  struct device_output_config config;
  config.output_size = output_size;
  config.output_offset = output_offset / sizeof(float);
  output_offset += output_size;
  return config;
}
struct device_output_config intelfpga_output_malloc(int8_t **dst,
                                                    int out_c,
                                                    int out_h,
                                                    int out_w)
{
  fpga_init();
  int output_channel_block = (out_c - 1) / INPUT_EXTEND_SCALE + 1;
  int output_size = output_channel_block * INPUT_CHANNEL_TILE * out_h * out_w;
  if (*dst == nullptr)
  {
    *dst = (int8_t *)udata + output_offset;
  }
  struct device_output_config config;
  config.output_size = output_size;
  config.output_offset = output_offset / INPUT_CHANNEL_TILE;
  output_offset += output_size;
  return config;
}

struct device_output_config intelfpga_add_output_malloc(int8_t **dst,
                                                        int out_c,
                                                        int out_h,
                                                        int out_w)
{
  fpga_init();
  int output_channel_block = (out_c - 1) / INPUT_EXTEND_SCALE + 1;
  int output_size = output_channel_block * INPUT_CHANNEL_TILE * out_h * out_w;
  if (*dst == nullptr)
  {
    *dst = (int8_t *)udata + output_offset;
  }
  struct device_output_config config;
  config.output_size = output_size;
  config.output_offset = output_offset / ADD_INPUT_EXTEND_SCALE;
  output_offset += output_size;
  return config;
}

int FpgaByte2WordOffset(int op_type, int byte_offset)
{
  int offset;
  switch (op_type)
  {
  case INTELFPGA_Conv2D:
  case INTELFPGA_DW_Conv2D:
    offset = byte_offset / INPUT_CHANNEL_TILE;
    break;
  default:
    std::cout << "[ByteOffset2WordOffset] Unsupported op: " << op_type
              << "\n";
    fpga_release();
    exit(-1);
  }
  return offset;
}

int FpgaWord2ByteOffset(int op_type, int word_offset)
{
  int offset;
  switch (op_type)
  {
  case INTELFPGA_Conv2D:
  case INTELFPGA_DW_Conv2D:
    offset = word_offset * INPUT_CHANNEL_TILE;
    break;
  default:
    std::cout << "[ByteOffset2WordOffset] Unsupported op: " << op_type
              << "\n";
    fpga_release();
    exit(-1);
  }
  return offset;
}

int FpgaGetOutputOffset(DeviceGraphNode *node)
{
  int offset;
  if (node->op_type_ == INTELFPGA_Conv2D ||
      node->op_type_ == INTELFPGA_DW_Conv2D)
  {
    auto param = dynamic_cast<FpgaConvParam *>(node->node_param_);
    offset = param->param.output_offset;
  }
  else
  {
    std::cout << "[FpgaGetOutputOffset] Unsupported op: " << node->op_type_
              << "\n";
    fpga_release();
    exit(-1);
  }

  return offset;
}

void FpgaReorganizeInput(DeviceGraphNode *node, int input_id, int layer)
{

  if (node->op_type_ == INTELFPGA_Conv2D ||
      node->op_type_ == INTELFPGA_DW_Conv2D)
  {
    auto argp = dynamic_cast<FpgaConvParam *>(node->node_param_);
#if LOG_OUT
    log_to_file(node->node_param_, layer, LOGOUT_REGIN_IN, (uint8_t *)argp->ia, argp->param.in_c * argp->param.in_h * argp->param.in_w, 16);
#endif
#if (REOGANIZE_TYPE == REOGANIZE_FPGA)
    memcpy((int8_t *)uorganize, (int8_t *)argp->ia, argp->param.in_c * argp->param.in_h * argp->param.in_w);

    data_reorganize(2,
                    argp->param.in_c,
                    argp->param.in_h * argp->param.in_w,
                    cb_org.phys,
                    cb_data.phys + FpgaWord2ByteOffset(node->op_type_, argp->param.input_offset));
#if LOG_OUT
    log_to_file(node->node_param_, layer, LOGOUT_REGIN_OUT, (uint8_t *)cb_data.addr + FpgaWord2ByteOffset(node->op_type_, argp->param.input_offset), argp->param.in_c * argp->param.in_h * argp->param.in_w, 16);
#endif

#elif (REOGANIZE_TYPE == REOGANIZE_ARM)
    InputRearrange((int8_t *)argp->ia, (int8_t *)((int8_t *)udata + FpgaWord2ByteOffset(node->op_type_, argp->param.input_offset)), argp->param.in_c, argp->param.in_h, argp->param.in_w, 0);
#endif
  }
  else
  {
    std::cout << "[FpgaReorganizeInput] Unsupported op: " << node->op_type_ << "\n";
    fpga_release();
    exit(-1);
  }
}

void FpgaOutputReorganize(DeviceGraphNode *node, int layer)
{
  if (node->op_type_ == INTELFPGA_Conv2D ||
      node->op_type_ == INTELFPGA_DW_Conv2D)
  {
    auto argp = dynamic_cast<FpgaConvParam *>(node->node_param_);
#if LOG_OUT
    log_to_file(node->node_param_, layer, LOGOUT_REGOUT_IN, (uint8_t *)udata + FpgaWord2ByteOffset(node->op_type_, argp->param.output_offset), argp->param.output_c * argp->param.output_h * argp->param.output_w, 16);
#endif
#if (REOGANIZE_TYPE == REOGANIZE_FPGA)

    data_reorganize(3,
                    argp->param.output_c,
                    argp->param.output_h * argp->param.output_w,
                    cb_data.phys + FpgaWord2ByteOffset(node->op_type_, argp->param.output_offset),
                    cb_org.phys);
#if LOG_OUT
    log_to_file(node->node_param_, layer, LOGOUT_REGOUT_OUT, (uint8_t *)cb_org.addr, argp->param.output_c * argp->param.output_h * argp->param.output_w, 16);
#endif


#elif (REOGANIZE_TYPE == REOGANIZE_ARM)
    OutputRearrange((int8_t *)((int8_t *)udata + FpgaWord2ByteOffset(node->op_type_, argp->param.output_offset)), //(int8_t *)argp->d_oa,
                    (int8_t *)uorganize,                                                                          //(int8_t*)argp->oa,
                    argp->param.output_c,
                    argp->param.output_h,
                    argp->param.output_w);
#if LOG_OUT
    log_to_file(node->node_param_, layer, LOGOUT_REGOUT_OUT, (uint8_t *)uorganize, argp->param.output_c * argp->param.output_h * argp->param.output_w, 16);
#endif
#endif
    global_mem_cfg.src = (int8_t *)uorganize;
    global_mem_cfg.dst = (int8_t *)argp->oa;
    global_mem_cfg.size =
        argp->param.output_c * argp->param.output_h * argp->param.output_w;
    global_mem_cfg.valid = true;
  }
  else
  {
    std::cout << "[FpgaReorganizeInput] Unsupported op: " << node->op_type_
              << "\n";
    fpga_release();
    exit(-1);
  }
}
struct device_output_config FpgaMemMalloc(
    int op_type, int8_t *dst, int c, int h, int w)
{
  auto config = device_output_config();
  switch (op_type)
  {
  case INTELFPGA_Conv2D:
  case INTELFPGA_DW_Conv2D:
    config = intelfpga_output_malloc(&dst, c, h, w);
    break;
  default:
    std::cout << "[DeviceMalloc] Unsupported op: " << op_type << "\n";
    fpga_release();
    exit(-1);
  }
  return config;
}

void PrintLayerConfig(parameter *param, std::ostream &log)
{
  static int layer = 0;
  // if (layer >= 1) {
  //   return;
  // }
  log << "param[" << layer << "].in_c = " << param->in_c << "; ";
  log << "param[" << layer << "].output_c = " << param->output_c << "; ";
  log << "param[" << layer << "].in_h = " << param->in_h << "; ";
  log << "param[" << layer << "].in_w = " << param->in_w << "; ";
  log << "param[" << layer << "].in_pad = " << param->in_pad << ";\n";
  log << "param[" << layer << "].output_h = " << param->output_h << "; ";
  log << "param[" << layer << "].output_w = " << param->output_w << "; ";
  log << "param[" << layer << "].out_pad = " << param->out_pad << ";\n";
  log << "param[" << layer << "].kernel = " << param->kernel << "; ";
  log << "param[" << layer << "].stride = " << param->stride << "; ";
  log << "param[" << layer << "].relu = " << param->relu << "; ";
  log << "param[" << layer << "].lr = " << param->lr << "; ";
  log << "param[" << layer << "].type = " << param->type << ";\n";
  log << "\n";
  layer++;
}


struct device_weight_config conv2d_weight_reorganize(int8_t *src,
                                                     int8_t **dst,
                                                     int out_c,
                                                     int in_c,
                                                     int kh,
                                                     int kw,
                                                     const char *filter_name)
{
  fpga_init();
  int output_channel, input_channel;
  int block_of_input_channel = (in_c - 1) / INPUT_CHANNEL_TILE + 1;
  int block_of_output_channel = (out_c - 1) / OUTPUT_CHANNEL_TILE + 1;
  int kernel_size = kh * kw;
  int block_size = INPUT_CHANNEL_TILE * kernel_size * WEIGHT_EXTEND_SCALE;
  int8_t temp;
  int weight_size = block_of_output_channel * block_of_input_channel *
                    INPUT_CHANNEL_TILE * kernel_size * WEIGHT_EXTEND_SCALE;
  if (*dst == nullptr)
  {
    *dst = (int8_t *)uweight + weight_offset;
  }
  struct device_weight_config config;
  config.weight_size = weight_size;
  config.weight_offset = weight_offset / INPUT_CHANNEL_TILE;
  weight_offset += weight_size;
  for (int i = 0; i < block_of_output_channel; i++)
  {
    for (int j = 0; j < block_of_input_channel; j++)
    {
      for (int ti = 0; ti < INPUT_CHANNEL_TILE; ti++)
      {
        for (int k = 0; k < kernel_size; k++)
        {
          for (int m = 0; m < WEIGHT_EXTEND_SCALE; m++)
          {
            input_channel = j * INPUT_CHANNEL_TILE + ti;
            output_channel = i * OUTPUT_CHANNEL_TILE + m;
            if (output_channel >= out_c || input_channel >= in_c)
              temp = 0;
            else
              temp = src[(output_channel * in_c + input_channel) * kernel_size +
                         k];
            (*dst)[(i * block_of_input_channel + j) * block_size +
                   (k + ti * kernel_size) * WEIGHT_EXTEND_SCALE + m] = temp;
          }
        }
      }
    }
  }
  return config;
}

struct device_weight_config dw_conv2d_weight_reorganize(
    int8_t *src, int8_t **dst, int out_c, int kh, int kw)
{
  fpga_init();
  int block_of_output_channel = (out_c - 1) / OUTPUT_CHANNEL_TILE + 1;
  int kernel_size = kh * kw;
  int block_size = OUTPUT_CHANNEL_TILE * INPUT_CHANNEL_TILE * kernel_size;
  int weight_size = block_of_output_channel * INPUT_CHANNEL_TILE * kernel_size *
                    WEIGHT_EXTEND_SCALE;
  int8_t temp;
  if (*dst == nullptr)
  {
    *dst = (int8_t *)uweight + weight_offset;
  }

  struct device_weight_config config;
  config.weight_size = weight_size;
  config.weight_offset = weight_offset / INPUT_CHANNEL_TILE;
  weight_offset += weight_size;

  for (int i = 0; i < block_of_output_channel; i++)
  {
    for (int ti = 0; ti < INPUT_CHANNEL_TILE; ti++)
    {
      for (int k = 0; k < kernel_size; k++)
      {
        for (int m = 0; m < WEIGHT_EXTEND_SCALE; m++)
        {
          if (ti == m)
            temp = src[i * OUTPUT_CHANNEL_TILE * kernel_size + m * kernel_size +
                       k];
          else
            temp = 0;
          (*dst)[i * block_size + (ti * kernel_size + k) * WEIGHT_EXTEND_SCALE +
                 m] = temp;
        }
      }
    }
  }
  return config;
}

void sw_dwconv(int8_t *input,
               int8_t *filter,
               INtype *output,
               struct parameter param,
               float *scale_factor)
{
  for (int m = 0; m < param.output_c; m++)
  {
    for (int h = 0; h < param.output_h; h++)
    {
      for (int w = 0; w < param.output_w; w++)
      {
        long long temp = 0;
        for (int kernel_h = 0; kernel_h < param.kernel; kernel_h++)
        {
          for (int kernel_w = 0; kernel_w < param.kernel; kernel_w++)
          {
            int ih = h * param.stride + kernel_h - param.in_pad;
            int iw = w * param.stride + kernel_w - param.in_pad;
            if ((ih < 0 || ih >= param.in_h) || (iw < 0 || iw >= param.in_w))
              continue;
            long long a =
                filter[m * param.kernel * param.kernel +
                       kernel_h * param.kernel + kernel_w] *
                input[m * param.in_h * param.in_w + ih * param.in_w + iw];
            temp += a;
          }
        }
        float scale = scale_factor[0] * scale_factor[2 + m] / scale_factor[1];
        float full = temp;
        full = (full * scale + scale_factor[2 + param.output_c + m]);
        float scale_6 = 6 / scale_factor[1];
        switch (param.relu)
        {
        case INTELFPGA_ACT_RELU:
          if (full < 0)
            full = 0;
          break;
        case INTELFPGA_ACT_RELU6:
          if (full < 0)
            full = 0;
          if (full > scale_6)
          {
            full = scale_6;
          }
          break;
        case INTELFPGA_ACT_LEAKYRELU:
          if (full < 0)
          {
            full = param.lr * full;
          }
          break;
        default:
          full = full;
        }
        INtype tmp = quantize(full);
        output[m * param.output_h * param.output_w + h * param.output_w + w] = tmp;
      }
    }
  }
}

void sw_conv(int8_t *input,
             int8_t *filter,
             int *mask,
             INtype *output,
             struct parameter param,
             float *scale_factor)
{
  std::cout << "Reakyrelu alpha: " << param.lr << "\n";
  int in_c_num = (param.in_c - 1) / INPUT_CHANNEL_TILE + 1;
  for (int m = 0; m < param.output_c; m++)
  {
    for (int h = 0; h < param.output_h; h++)
    {
      for (int w = 0; w < param.output_w; w++)
      {
        int temp = 0;
        for (int n = 0; n < in_c_num; n++)
        {
#ifdef PRUNE
          for (int ti = 0; ti < DENSE_INPUT_CHANNEL_TILE; ti++)
          {
#else
          for (int ti = 0; ti < INPUT_CHANNEL_TILE; ti++)
          {
#endif
            for (int kernel_h = 0; kernel_h < param.kernel; kernel_h++)
            {
              for (int kernel_w = 0; kernel_w < param.kernel; kernel_w++)
              {
                int ih = h * param.stride + kernel_h - param.in_pad;
                int iw = w * param.stride + kernel_w - param.in_pad;

                if ((ih < 0 || ih >= param.in_h) ||
                    (iw < 0 || iw >= param.in_w))
                  continue;
#ifdef PRUNE
                int index =
                    mask[(((m * in_c_num + n) * DENSE_INPUT_CHANNEL_TILE + ti) *
                              param.kernel +
                          kernel_h) *
                             param.kernel +
                         kernel_w];
#else
                int index = ti;
#endif
                if (index >= param.in_c)
                {
                  continue;
                }

                temp += filter[m * param.in_c * param.kernel * param.kernel +
                               (n * INPUT_CHANNEL_TILE + index) * param.kernel *
                                   param.kernel +
                               kernel_h * param.kernel + kernel_w] *
                        input[(n * INPUT_CHANNEL_TILE + index) * param.in_h *
                                  param.in_w +
                              ih * param.in_w + iw];
              }
            }
          }
        }

        float f = temp;
        float scale =
            scale_factor[0] * scale_factor[2 + m] /
            scale_factor
                [1]; //+scale_factor.bias_scale*filter[param.in_c*param.output_c*param.kernel*param.kernel+m];
        f = f * scale + scale_factor[2 + param.output_c + m];
        float scale_6 = 6 / scale_factor[1];
        switch (param.relu)
        {
        case INTELFPGA_ACT_RELU:
          if (f < 0)
            f = 0;
          break;
        case INTELFPGA_ACT_RELU6:
          if (f < 0)
            f = 0;
          if (f > scale_6)
          {
            f = scale_6;
          }
          break;
        case INTELFPGA_ACT_LEAKYRELU:
          if (f < 0)
          {
            f = param.lr * f;
          }
          break;
        default:
          f = f;
        }
        temp = quantize(f);
        output[m * param.output_h * param.output_w + h * param.output_w + w] =
            temp;
      }
    }
  }
}

void ExecuteSomeTime()
{
  int d = 0;
  for (int i = 0; i < 1000; i++)
  {
    d++;
  }
  return;
}

int intelfpga_subgraph(struct DeviceGraphNode *node)
{
  fpga_init();
#ifdef PROFILE
  printf("------------------graph begin------\n");
  struct timespec hw_start, hw_end;
  long long input_organize_time, output_organize_time = 0;
  long long fpga_time = 0;
#if LOG_OUT
  mkdir("log", 0755);
#endif
#endif
  static int num_node = 0;
  while (node != nullptr)
  {
    // printf("---layer:%d,optype:%d---\r\n",num_node,node->op_type_);

    if (node->is_input)
    {
#ifdef PROFILE
      clock_gettime(CLOCK_MONOTONIC, &hw_start);
#endif
      for (int i = 0; i < node->parent_vec_.size(); i++)
      {
        if (node->parent_vec_[i] == nullptr)
        {
          FpgaReorganizeInput(node, i, num_node);
        }
      }
#ifdef PROFILE
      clock_gettime(CLOCK_MONOTONIC, &hw_end);
      input_organize_time = (long long)(hw_end.tv_sec - hw_start.tv_sec) * (1000000000) + hw_end.tv_nsec - hw_start.tv_nsec;
#endif
    }
    if (node->op_type_ == INTELFPGA_Conv2D || node->op_type_ == INTELFPGA_DW_Conv2D)
    {
      // std::cout << "Info: the operator " << node->name_ << " is support!\n" << std::endl;
      // std::cout << "hardware conv2d.\n";
      auto argp = dynamic_cast<FpgaConvParam *>(node->node_param_);

#ifdef PROFILE
      clock_gettime(CLOCK_MONOTONIC, &hw_start);
#endif
      argp->param.output_row_tile = std::min(
          OUTPUT_BUFF_SIZE / argp->param.output_w, argp->param.output_h);
      argp->param.input_row_tile =
          (argp->param.output_row_tile - 1) * argp->param.stride +
          argp->param.dilation * (argp->param.kernel - 1) + 1;
      argp->param.output_channel_block_num =
          up_round(argp->param.output_c, OUTPUT_CHANNEL_TILE);
      argp->param.output_row_block_num =
          up_round(argp->param.output_h, argp->param.output_row_tile);

#if PRINT_DBG
    if (node->op_type_ == INTELFPGA_Conv2D || node->op_type_ == INTELFPGA_DW_Conv2D)
      PrintDeviceParam(node, num_node); // PrintDeviceParam(&dynamic_cast<FpgaConvParam*>(node->node_param_)->param,num_node);
#endif

      memset(uparam, 0, sizeof(parameter));
      memcpy(uparam, (int *)(&(argp->param)), sizeof(struct parameter));

      memcpy((float *)uscale, argp->scale, sizeof(float) * (2 * argp->param.output_c));

      if (global_mem_cfg.valid)
      {
        memcpy(global_mem_cfg.dst, global_mem_cfg.src, global_mem_cfg.size);
        global_mem_cfg.valid = false;
      }
#if LOG_OUT
      log_to_file(node->node_param_, num_node,
                  LOGOUT_CONV_IN,
                  (uint8_t *)udata + FpgaWord2ByteOffset(INTELFPGA_Conv2D, argp->param.input_offset),
                  argp->param.in_c * argp->param.in_h * argp->param.in_w, 16);
#endif
      start_fpga(foo, FPGAREG_CNN_START);
#if LOG_OUT
      log_to_file(node->node_param_, num_node,
                  LOGOUT_CONV_OUT,
                  (uint8_t *)udata + FpgaWord2ByteOffset(INTELFPGA_Conv2D, argp->param.output_offset),
                  argp->param.output_c * argp->param.output_h * argp->param.output_w, 16);
#endif

#ifdef PROFILE
      clock_gettime(CLOCK_MONOTONIC, &hw_end);
      fpga_time += (long long)(hw_end.tv_sec - hw_start.tv_sec) * (1000000000) + hw_end.tv_nsec - hw_start.tv_nsec;
#endif
    }
    else
    {
      std::cout << "Error: the operator " << node->name_ << " is not supported in cnn_top! pls excute the operator with arm. the process will be terminate.\n" << std::endl;
      fpga_release();
      exit(-1);
    }
    if (node->is_output && !SDK_EMULATE)
    {
#ifdef PROFILE
      clock_gettime(CLOCK_MONOTONIC, &hw_start);
#endif
      FpgaOutputReorganize(node, num_node);
#ifdef PROFILE
      clock_gettime(CLOCK_MONOTONIC, &hw_end);
      output_organize_time += (long long)(hw_end.tv_sec - hw_start.tv_sec) * (1000000000) + hw_end.tv_nsec - hw_start.tv_nsec;
#endif
    }
    node = node->next_;
    num_node++;
  }
  if (global_mem_cfg.valid)
  {
    memcpy(global_mem_cfg.dst, global_mem_cfg.src, global_mem_cfg.size);
    global_mem_cfg.valid = false;
  }
#ifdef PROFILE
  printf("input_organize_time:%fms\n", (float)(input_organize_time / 1000000.0f));
  printf("fpga_time:%fms\n", (float)(fpga_time / 1000000.0f));
  printf("output_organize_time:%fms\n", (float)(output_organize_time / 1000000.0f));

  printf("------------------graph end------\n");
#endif
  return 0;
}
