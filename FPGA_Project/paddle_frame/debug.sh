#!/bin/sh
insmod cmadrv.ko
export LD_LIBRARY_PATH=./opencv_lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=intelfpga_sdk/lib/build:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/bananasuper/work/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/api/:$LD_LIBRARY_PATH+
chmod u+x /home/bananasuper/work/nna/ssd_detection_demo/ssd_detection_src/build/ssd_detection
gdb --args /home/bananasuper/work/nna/ssd_detection_demo/ssd_detection_src/build/ssd_detection config.txt dog.jpg
