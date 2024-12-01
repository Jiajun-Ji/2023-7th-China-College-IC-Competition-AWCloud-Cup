rsync -rvlt --exclude-from=exclude.list  ./Paddle-Lite root@$AIEP_HOST:/home/huangchao/work/nna
rsync -rvlt --exclude-from=exclude.list  ./intelfpga_sdk root@$AIEP_HOST:/home/huangchao/work/nna
rsync -rvlt --exclude-from=exclude.list  ./ssd_detection_demo root@$AIEP_HOST:/home/huangchao/work/nna
cp cmadrv/build/cmadrv.ko paddle_frame
rsync -rvlt --exclude-from=exclude.list  ./paddle_frame root@$AIEP_HOST:/opt
