// Copyright (c) 2021 PaddlePaddle Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <fstream>
#include <iostream>
#include <vector>
#include <chrono>
#include <numeric>
#include <stdio.h>
#include <sys/times.h>
#include <unistd.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <linux/fb.h>
#include <linux/videodev2.h>
#include <arm_neon.h>

#include <opencv2/opencv.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/core/core.hpp>

#include "paddle_api.h"  // NOLINT
#include "intelfpga.h"
 #include <sys/mman.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <linux/ioctl.h>
#include <unistd.h>
#include <string.h>

#define soc_cv_av

#include "hwlib.h"
#include "socal.h"
#include "hps.h"
#include "hps_0.h"


#include <stdio.h>
#include <unistd.h>
#include <sys/shm.h>
#include <stdlib.h>
#include <error.h>
#include <string.h>

using namespace paddle::lite_api;  // NOLINT
using namespace std;
using namespace cv;
using namespace std;

// #define HW_REGS_BASE (ALT_STM_OFST)
// #define HW_REGS_SPAN (0x04000000)
// #define HW_REGS_MASK (HW_REGS_SPAN - 1)

// #define AMM_WR_MAGIC 'x'
// #define AMM_WR_CMD_DMA_BASE _IOR(AMM_WR_MAGIC, 0x1a, int)
// #define AMM_WR_CMD_PHY_BASE _IOR(AMM_WR_MAGIC,0x1b,int)

// #define IMG_WIDTH  400
// #define IMG_HEIGHT 320
// #define BURST_LEN 48

// #define IMG_BUF_SIZE IMG_WIDTH * IMG_HEIGHT * 3

// static unsigned char *transfer_data_base = NULL;
// static unsigned char *p_transfer_data_base = NULL;
// static volatile unsigned int *dvp_ddr3_cfg_base = NULL;//寄存器
// static volatile unsigned int *ddr3_vga_cfg_base = NULL;//寄存器

//-----------------------------新IP-----------------------------------------

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


//虚拟地址，PS端需要
static volatile unsigned int *master_ctrl_virtual_base = NULL;	//写主机控制模块虚拟地址
static volatile unsigned int *ddr3_vga_cfg_base = NULL;//ddr3_vga控制模块虚拟地址(官方)
static volatile unsigned int *ddr3_vga_top_virtual_base = NULL;//ddr3_vga_top控制模块虚拟地址(自己的ip)
static unsigned char *transfer_data_base = NULL;//dma虚拟地址，便于hps操控
//物理地址，PL端需要
static volatile unsigned long dma_base; /*DMA传输物理基地址*/

//-----------------------------新IP结束-----------------------------------------

const int CPU_THREAD_NUM = 4;
const paddle::lite_api::PowerMode CPU_POWER_MODE =
    paddle::lite_api::PowerMode::LITE_POWER_HIGH;
std::stringstream LOG_MEM;

std::shared_ptr<PaddlePredictor> predictor;

struct Object {
  cv::Rect rec;
  int class_id;
  float prob;
};

class Timer {
private:
   std::chrono::high_resolution_clock::time_point inTime, outTime;
public:
  void startTimer() { inTime = std::chrono::high_resolution_clock::now(); }
  // unit millisecond
  float getCostTimer() {
    outTime = std::chrono::high_resolution_clock::now();
    return static_cast<float>(
       std::chrono::duration_cast<std::chrono::microseconds>(outTime - inTime)
       .count() / 1e+3);
  }
};

class Timer2 {
private:
  tms time_start, time_end;
  int sc_clk_tck;
  clock_t head, tail;
public:
  Timer2() {
    sc_clk_tck = sysconf(_SC_CLK_TCK);
  }
  void startTimer() {
    head = times(&time_start);
  }
  void getCostTimer() {
    tail = times(&time_end);
    std::cout << "Real time (second): " << (tail - head) / (double)sc_clk_tck << "\n";
    //std::cout << " User time: " << (time_end.tms_utime - time_start.tms_utime) / (double) sc_clk_tck << "\n";
    //std::cout << " Sys time: " << (time_end.tms_stime - time_start.tms_stime) / (double) sc_clk_tck << "\n";
    //std::cout << " Child sys time: " << (time_end.tms_cstime - time_start.tms_cstime) / (double) sc_clk_tck << "\n";
    //std::cout << " Process time: " << ((time_end.tms_cstime - time_start.tms_cstime) +
    //    (time_end.tms_utime - time_start.tms_utime)
    //    +(time_end.tms_stime - time_start.tms_stime)
    //    )/ (double) sc_clk_tck << "\n";
  }
};

// Object for storing all preprocessed data
struct ImageBlob {
  // image width and height
  std::vector<float> im_shape_;
  // Buffer for image data after preprocessing
  const float* im_data_;
  // Scale factor for image size to origin image size
  std::vector<float> scale_factor_;
  std::vector<float> mean_;
  std::vector<float> scale_;
};

void PrintBenchmarkLog(std::vector<double> det_time,
                       std::map<std::string, std::string> config,
                       int img_num) {
  std::cout << "----------------- Config info ------------------" << std::endl;
  std::cout << "runtime_device: armv8" << std::endl;
  std::cout << "precision: " << config.at("precision") << std::endl;

  std::cout << "num_threads: " << config.at("num_threads") << std::endl;
  std::cout << "---------------- Data info ---------------------" << std::endl;
  std::cout << "batch_size: " << 1 << std::endl;
  std::cout << "---------------- Model info --------------------" << std::endl;
  std::cout << "Model_name: " << config.at("model_file") << std::endl;
  std::cout << "---------------- Perf info ---------------------" << std::endl;
  std::cout << "Total number of predicted data: " << img_num
            << " and total time spent(s): "
            << std::accumulate(det_time.begin(), det_time.end(), 0) << std::endl;
  std::cout << "preproce_time(ms): " << det_time[0] / img_num
            << ", inference_time(ms): " << det_time[1] / img_num
            << ", postprocess_time(ms): " << det_time[2] << std::endl;
}

std::vector<std::string> LoadLabels(const std::string &path) {
  std::ifstream file;
  std::vector<std::string> labels;
  file.open(path);
  while (file) {
    std::string line;
    std::getline(file, line);
    std::string::size_type pos = line.find(" ");
    if (pos != std::string::npos) {
      line = line.substr(pos);
    }
    labels.push_back(line);
  }
  file.clear();
  file.close();
  return labels;
}

std::vector<std::string> ReadDict(std::string path) {
  std::ifstream in(path);
  std::string filename;
  std::string line;
  std::vector<std::string> m_vec;
  if (in) {
    while (getline(in, line)) {
      m_vec.push_back(line);
    }
  } else {
    std::cout << "no such file" << std::endl;
  }
  return m_vec;
}

std::vector<std::string> split(const std::string &str,
                               const std::string &delim) {
  std::vector<std::string> res;
  if ("" == str)
    return res;
  char *strs = new char[str.length() + 1];
  std::strcpy(strs, str.c_str());

  char *d = new char[delim.length() + 1];
  std::strcpy(d, delim.c_str());

  char *p = std::strtok(strs, d);
  while (p) {
    string s = p;
    res.push_back(s);
    p = std::strtok(NULL, d);
  }

  return res;
}

std::map<std::string, std::string> LoadConfigTxt(std::string config_path) {
  auto config = ReadDict(config_path);

  std::map<std::string, std::string> dict;
  for (int i = 0; i < config.size(); i++) {
    std::vector<std::string> res = split(config[i], " ");
    dict[res[0]] = res[1];
  }
  return dict;
}

void PrintConfig(const std::map<std::string, std::string> &config) {
  std::cout << "=======PaddleDetection lite demo config======" << std::endl;
  for (auto iter = config.begin(); iter != config.end(); iter++) {
    std::cout << iter->first << " : " << iter->second << std::endl;
  }
  std::cout << "===End of PaddleDetection lite demo config===" << std::endl;
}


// fill tensor with mean and scale and trans layout: nhwc -> nchw, neon speed up
void neon_mean_scale(const float* din,
                     float* dout,
                     int size,
                     const std::vector<float> mean,
                     const std::vector<float> scale) {
  if (mean.size() != 3 || scale.size() != 3) {
    std::cerr << "[ERROR] mean or scale size must equal to 3\n";
    exit(1);
  }
  float32x4_t vmean0 = vdupq_n_f32(mean[0]);
  float32x4_t vscale0 = vdupq_n_f32(1.f / scale[0]);
  float* dout_c0 = dout;
  int i = 0;
  #pragma unroll(4)
  // #pragma omp parallel for num_threads(2)
  for (i=0; i < size - 3; i += 4) {
    float32x4_t vin3 = vld1q_f32(din);
    float32x4_t vsub0 = vsubq_f32(vin3, vmean0);
    float32x4_t vs0 = vmulq_f32(vsub0, vscale0);
    vst1q_f32(dout_c0, vs0);
    din += 4;
    dout_c0 += 4;
  }
  for (; i < size; i++) {
    *(dout_c0++) = (*(din++) - mean[0]) / scale[0];
  }
}

std::vector<Object> visualize_result(
                        const float* data,
                        int count,
                        float thresh,
                        cv::Mat& image,
                        const std::vector<std::string> &class_names) {
  if (data == nullptr) {
    std::cerr << "[ERROR] data can not be nullptr\n";
    exit(1);
  }
  std::vector<Object> rect_out;

  struct timeval tv;
  struct timezone tz;  
  struct tm *t;
  gettimeofday(&tv, &tz);
  t = localtime(&tv.tv_sec);
  std::cout << "[" << 1900+t->tm_year << "-" << 1+t->tm_mon << "-" << t->tm_mday << " " << t->tm_hour << ":" << t->tm_min << ":" << t->tm_sec << "." <<tv.tv_usec / 1000 << "]"
            << std::endl;

  for (int iw = 0; iw < count; iw++) {
    int oriw = image.cols;
    int orih = image.rows;
    if (data[1] > thresh) {
      Object obj;
      int x = static_cast<int>(data[2]);
      int y = static_cast<int>(data[3]);
      int w = static_cast<int>(data[4] - data[2] + 1);
      int h = static_cast<int>(data[5] - data[3] + 1);
      cv::Rect rec_clip =
          cv::Rect(x, y, w, h) & cv::Rect(0, 0, image.cols, image.rows);
      obj.class_id = static_cast<int>(data[0]);
      obj.prob = data[1];
      obj.rec = rec_clip;

      if (w > 0 && h > 0 && obj.prob <= 1) {
        rect_out.push_back(obj);
        cv::rectangle(image, rec_clip, cv::Scalar(255, 255, 255), 1, cv::LINE_AA);
        std::string str_prob = std::to_string(obj.prob);
        std::string text = std::string(class_names[obj.class_id]) + ": " +
                           str_prob.substr(0, str_prob.find(".") + 4);
        int font_face = cv::FONT_HERSHEY_COMPLEX_SMALL;
        double font_scale = 1.f;
        int thickness = 1;
        cv::Size text_size =
            cv::getTextSize(text, font_face, font_scale, thickness, nullptr);
        float new_font_scale = 100 * font_scale / text_size.width;
        text_size = cv::getTextSize(
            text, font_face, new_font_scale, thickness, nullptr);
        cv::Point origin;
        origin.x = x + 3;
        origin.y = y + text_size.height + 3;



        cv::putText(image,
                    text,
                    origin,
                    font_face,
                    new_font_scale,
                    cv::Scalar(255, 255, 255),
                    thickness,
                    cv::LINE_AA);

        // std::cout << "success detection, image size: " << image.cols << ", "
        //           << image.rows
        //           << ", detect object: " << class_names[obj.class_id]
        //           << ", score: " << obj.prob << ", location: x=" << x
        //           << ", y=" << y << ", width=" << w << ", height=" << h
        //           << std::endl;
      }
    }
    data += 6;
  }
  printf("--------------------------------------------------------------------------------------------------\n");
  return rect_out;
}

// Load Model and create model predictor
std::shared_ptr<PaddlePredictor> LoadModel(std::string model_file,
                                           int num_theads) {
   MobileConfig config;
   config.set_model_from_file(model_file);
   config.set_threads(num_theads);
   config.set_power_mode(CPU_POWER_MODE);
   std::shared_ptr<PaddlePredictor> predictor =
   CreatePaddlePredictor<MobileConfig>(config);
  return predictor;

}

ImageBlob prepare_imgdata(const cv::Mat& img,
                          std::map<std::string,
                          std::string> config) {
  ImageBlob img_data;
  std::vector<int> target_size_;
  std::vector<std::string> size_str = split(config.at("Resize"), ",");
  transform(size_str.begin(), size_str.end(), back_inserter(target_size_),
            [](std::string const& s){return stoi(s);});
  int width = 400;
  int height = 300;
  img_data.im_shape_ = {
      static_cast<float>(target_size_[0]),
      static_cast<float>(target_size_[1])
  };
      
  img_data.scale_factor_ = {
    static_cast<float>(target_size_[0]) / static_cast<float>(img.rows),
    static_cast<float>(target_size_[1]) / static_cast<float>(img.cols)
  };
  std::vector<float> mean_;
  std::vector<float> scale_;
  std::vector<std::string> mean_str = split(config.at("mean"), ",");
  std::vector<std::string> std_str = split(config.at("std"), ",");
  transform(mean_str.begin(), mean_str.end(), back_inserter(mean_),
            [](std::string const& s){return stof(s);});
  transform(std_str.begin(), std_str.end(), back_inserter(scale_),
            [](std::string const& s){return stof(s);});
  img_data.mean_ = mean_;
  img_data.scale_ = scale_;
  return img_data;
}

void preprocess(const cv::Mat& img, const ImageBlob img_data, float* data) {
  cv::Mat rgb_img;
  Timer timer;
  timer.startTimer();

  cv::resize(
      img, rgb_img, cv::Size(img_data.im_shape_[0],img_data.im_shape_[1]),
      0.f, 0.f, cv::INTER_CUBIC);
  std::cout << "resize time:" << timer.getCostTimer() << "ms" << "\n";

  cv::Mat imgf;
  timer.startTimer();
  rgb_img.convertTo(imgf, CV_32FC1, 1/*1 / 255.fi*/);
  const float* dimg = reinterpret_cast<const float*>(imgf.data);
  std::cout << "convert time:" << timer.getCostTimer() << "ms" << "\n";
  timer.startTimer();
  neon_mean_scale(
    dimg, data, int(img_data.im_shape_[0] * img_data.im_shape_[1]),
    img_data.mean_, img_data.scale_);
  std::cout << "neon time:" << timer.getCostTimer() << "ms" << "\n";
}

//-----------------------------------官方ip--------------------------
// int my_fpga_init(void)
// {
// 	void *per_virtual_base;
// 	int transfer_fd;
// 	int mem_fd;

// 	system("insmod amm_wr_drv.ko");

// 	transfer_fd = open("/dev/amm_wr", (O_RDWR|O_SYNC));
// 	if(transfer_fd == -1)
// 	{
// 		printf("open amm_wr is failed\n");
// 		return(0);
// 	}
// 	mem_fd = open("/dev/mem", (O_RDWR|O_SYNC));
// 	if(mem_fd == -1)
// 	{
// 		printf("open mmu is failed\n");
// 		return(0);
// 	}

// 	ioctl(transfer_fd, AMM_WR_CMD_DMA_BASE, &p_transfer_data_base);
// 	printf("p_transfer_data_base = %x\n", p_transfer_data_base);

// 	transfer_data_base = (unsigned char *)mmap(NULL, IMG_BUF_SIZE * 3, (PROT_READ | PROT_WRITE), MAP_SHARED, mem_fd, (unsigned int)p_transfer_data_base);

// 	per_virtual_base = (unsigned int*)mmap(NULL, HW_REGS_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, mem_fd, HW_REGS_BASE);

// 	dvp_ddr3_cfg_base = (unsigned int *)(per_virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + DVP_DDR3_0_BASE) & (unsigned long)(HW_REGS_MASK)));
// 	ddr3_vga_cfg_base = (unsigned int *)(per_virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + DDR3_VGA_0_BASE) & (unsigned long)(HW_REGS_MASK)));

	
// 	*dvp_ddr3_cfg_base = (unsigned int)p_transfer_data_base;
// 	*(dvp_ddr3_cfg_base + 1) = IMG_BUF_SIZE;
// 	*(dvp_ddr3_cfg_base + 2) = 0x00000000;

// 	//config ddr3_vga
// 	*ddr3_vga_cfg_base = (unsigned int)(p_transfer_data_base + IMG_BUF_SIZE);
// 	*(ddr3_vga_cfg_base + 1) = IMG_BUF_SIZE;
// 	*(ddr3_vga_cfg_base + 2) = 0x00000000;

// 	usleep(1000000);

// 	return 1;
// }


//--------------------------------------新ip----------------------------
int my_fpga_init(long int *virtual_base)
{
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
	master_ctrl_virtual_base = (unsigned int *)(periph_virtual_base
			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + DVP_DDR3_TOP_0_BASE)
					& (unsigned long) ( HW_REGS_MASK)));

	//映射得到写主机控制模块虚拟地址(ddr3_vga_top)
	ddr3_vga_top_virtual_base = (unsigned int *)(periph_virtual_base
			+ ((unsigned long) ( ALT_LWFPGASLVS_OFST + DDR3_VGA_TOP_0_BASE)
					& (unsigned long) ( HW_REGS_MASK)));

	//映射得到ddr3_vga控制模块虚拟地址
	ddr3_vga_cfg_base = (unsigned int *)(periph_virtual_base + ((unsigned long)(ALT_LWFPGASLVS_OFST + DDR3_VGA_0_BASE) & (unsigned long)(HW_REGS_MASK)));

	*virtual_base = (long int)periph_virtual_base; //将外设虚拟地址保存，用以释放时候使用
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


	return fd;
}

//----------------------------新IP结束--------------------------


//共享内存通信
typedef struct
{
    float a[100] = {};
    int64_t cnt;

}data, *dataprt;

dataprt share;
int shm_id;


//虚拟地址读写
int dma_fd;
int fpga_fd;
long int virtual_base = 0;	//虚拟基地址
//--------------------------------新IP-------------------------
void RunHdmi(std::map<std::string, std::string> config,
              std::string img_path,
              const int repeats,
              std::vector<double>* times) {
  std::string model_file = config.at("model_file");
  std::string label_path = config.at("label_path");


  char *addr;
  unsigned char buf[384000];
  int my_height = 300;
	int my_width = 400;
  int my_cnts=0;

  int write_flag = 0;
  //新IP参数

  // int dma_fd;
	// int fpga_fd;
	// long int virtual_base = 0;	//虚拟基地址


  //共享内存初始化
  data sturead;
  //放入全局变量，中断时销毁
  // int shm_id;
  // dataprt share;
  int64_t cnt =0;
  shm_id = shmget (1234, getpagesize(), IPC_CREAT);
  if (shm_id == -1) {
      perror("shmget()");
  }
  share = (dataprt)shmat(shm_id, 0, 0);


  //共享内存初始化结束


  // 加载标签
  std::vector<std::string> class_names = LoadLabels(label_path);

  //----------------------------------------初始化视频流-----------------------------------
  //完成fpga侧外设虚拟地址映射
	fpga_fd = my_fpga_init(&virtual_base);

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


  //----------------------------------------视频流初始化结束-----------------------------------
  //图片存储变量
  cv::Mat img(320, 400, CV_8UC1);
  //启动定时器
  Timer timer;


  //循环读取
  while(1)
  {
    // std::cout << "FPS run:" << timer.getCostTimer() << "ms" << "\n";
    // timer.startTimer();

    //读取图片
    int read_state = master_ctrl_virtual_base[3];
    if(read_state == 0x1)//该值为1代表着dvp写入的是buffer0，则从buffer1中读
    {
      // printf("read buffer0\n");
      memcpy(buf, transfer_data_base+ IMG_BUF_SIZE, IMG_BUF_SIZE);//vga写buffer3
      // ddr3_vga_top_virtual_base[1] = dma_base + IMG_BUF_SIZE * 3;//vga读buffer4
    }
    else//该值为0代表着dvp写入的是buffer1，则从buffer0中读
    {
      // printf("read buffer1\n");
      memcpy(buf, transfer_data_base , IMG_BUF_SIZE);//vga写buffer4
      // ddr3_vga_top_virtual_base[1] = dma_base + IMG_BUF_SIZE * 2;//vga读buffer3
    }

    // std::cout << "read buf:" << timer.getCostTimer() << "ms" << "\n";

    // printf("begin read\n");
    //   // cv::Mat img(300, 400, CV_8UC1);
    // printf("chuang jian over\n");
    for (int row = 0; row < 320; row++)
    {	
      //指向矩阵当前行的指针
      Vec<uchar, 1> *data_Ptr = img.ptr<Vec<uchar, 1>> (row);
      //可以将data_Ptr看出一个数组，data_Ptr[col]代表了第几个元素
      //每个元素的数据类型是<ushort,2>，包含了2个无符号整型的元素
      for (int col = 0; col < 400; col++)
      {
        data_Ptr[col][0] = (unsigned char)buf[((row)*400+col)];
        // data_Ptr[col][1] = (unsigned char)((buf[((10+row)*my_width+col)*3+1]*alpha+beta)>255?255:(buf[((10+row)*my_width+col)*3+1]*alpha+beta));
        // data_Ptr[col][2] = (unsigned char)((buf[((10+row)*my_width+col)*3+0]*alpha+beta)>255?255:(buf[((10+row)*my_width+col)*3+0]*alpha+beta));
      }
    }
    // printf("read_over\n");
    //测试用
    // std::string result_name =
    // img_path.substr(0, img_path.find(".")) + "_result.jpg";
    // cv::imwrite(result_name, img);
    // printf("vis_over\n");

    //共享内存，得到推理结果
    memcpy(&sturead, share, sizeof(sturead));

    auto rec_out = visualize_result(
        sturead.a, static_cast<int>(sturead.cnt / 6), 0.6f, img, class_names);

    for (int row = 0; row < 320; row++)
    {	
      //指向矩阵当前行的指针
      Vec<uchar, 1> *data_Ptr = img.ptr<Vec<uchar, 1>> (row);
      //可以将data_Ptr看出一个数组，data_Ptr[col]代表了第几个元素
      //每个元素的数据类型是<ushort,2>，包含了2个无符号整型的元素
      for (int col = 0; col < 400; col++)
      {
        buf[((row)*400+col)]=data_Ptr[col][0] ;
      }
    }
    
    // 输出图像测试
    if(read_state == 0x01)
    {
      // printf("write buffer1\n\n");
      memcpy(transfer_data_base + IMG_BUF_SIZE* 2, buf, IMG_BUF_SIZE);//vga写buffer3
      ddr3_vga_top_virtual_base[1] = dma_base + IMG_BUF_SIZE * 2;//vga读buffer4
      // write_flag = 1;
      // std::cout << "HDMI refresh time:" << timer.getCostTimer() << "ms" << "\n\n";
      // timer.startTimer();
    }
    else
    {
      // printf("write buffer0\n\n");
      memcpy(transfer_data_base + IMG_BUF_SIZE* 3, buf, IMG_BUF_SIZE);//vga写buffer3
      ddr3_vga_top_virtual_base[1] = dma_base + IMG_BUF_SIZE * 3;//vga读buffer4
      // write_flag = 0;
      // std::cout << "HDMI refresh time:" << timer.getCostTimer() << "ms" << "\n\n";
      // timer.startTimer();
    }

    // //输出图像
    // if(master_ctrl_virtual_base[3] == 0x1)//该值为1代表着dvp写入的是buffer0，则从buffer1中读
    // {
    //   printf("write buffer0\n");
    //   memcpy(transfer_data_base + IMG_BUF_SIZE* 2, buf, IMG_BUF_SIZE);//vga写buffer3
    // }
    // else//该值为0代表着dvp写入的是buffer1，则从buffer0中读
    // {
    //   printf("write buffer1\n");
    //   memcpy(transfer_data_base + IMG_BUF_SIZE * 3, buf , IMG_BUF_SIZE);//vga写buffer4
    // }

    usleep(28000);

  }
}




void int_handler(int sig)
{
  if (shmdt(share) < 0)
  {
    perror("failed to shmdt");
    // exit(-1);
  }

  if (shmctl(shm_id, IPC_RMID, NULL) == -1)
  {
    perror("failed to delete share memory");
    // exit(-1);
  }
  printf("delete_done\n");
  //取消虚拟地址映射，视频流

  if (munmap((void*)virtual_base, HW_REGS_SPAN) != 0) 
  {
    printf("ERROR: munmap() failed...\n");
    close(fpga_fd);
  }
  close(fpga_fd);
  close(dma_fd); //关闭MPU

  fflush(stdout);
  fpga_release();
  exit(-1);
  printf("SIGINT: stopping the predictor\n");
}

int main(int argc, char** argv) {
  if (argc < 3) {
    std::cerr << "[ERROR] usage: " << argv[0] << " config_path image_path\n";
    exit(1);
  }
  fpga_release();
  std::string config_path = argv[1];
  std::string img_path = argv[2];

  signal(SIGINT, int_handler);

  // load config
  auto config = LoadConfigTxt(config_path);
  PrintConfig(config);

  bool enable_benchmark = bool(stoi(config.at("enable_benchmark")));
  int repeats = enable_benchmark ? 50: 1;
  std::vector<double> det_times;

  RunHdmi(config, img_path, repeats, &det_times);

  // PrintBenchmarkLog(det_times, config, 1);
  // std::cout << LOG_MEM.str();

  // void *handle=dlopen("../Paddlelite/lib/libvnna.so",RTLD_LAZY);
  // void (*fpga_release)(void);
  // fpga_release = (void (*)())dlsym(handle,"fpga_release");
  fpga_release();
  return 0;
}
