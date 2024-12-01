#!/bin/sh
insmod cmadrv.ko
insmod amm_wr_drv.ko
export LD_LIBRARY_PATH=./opencv_lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./paddlelite_lib:$LD_LIBRARY_PATH+
chmod u+x ssd_detection
# taskset -c 1,0 nice -n -20 ./ssd_detection config.txt 1.jpg
nice -n -20 ./ssd_detection config.txt 1.jpg
