cp cmadrv/build/cmadrv.ko paddle_frame
cp intelfpga_sdk/lib/build/libvnna.so paddle_frame/paddlelite_lib
cp Paddle-Lite/build.lite.linux.armv7hf.gcc/inference_lite_lib.armlinux.armv7hf.intel_fpga/cxx/lib/libpaddle_full_api_shared.so paddle_frame/paddlelite_lib
cp ssd_detection_demo/ssd_detection_src/build/ssd_detection paddle_frame/
cp ssd_detection_demo/ssd_hdmi/build/ssd_hdmi paddle_frame/
cp ssd_detection_demo/ssd_inference_once/build/ssd_inference_once paddle_frame/
rsync -rvlt --exclude-from=exclude.list  ./paddle_frame root@$AIEP_HOST:/opt
