#!/bin/bash
if [ "$1" = "" ];
then
	echo "usage:./build.sh <ARCH_ABI(armv7hf or armv8)>"
	exit
else
	if [ "$1" = "armv8" ];
	then
		./lite/tools/build_linux.sh --arch=armv8 --with_extra=ON --with_log=ON --with_intel_fpga=ON --intel_fpga_sdk_root=../intelfpga_sdk full_publish
		cp build.lite.linux.armv8.gcc/inference_lite_lib.armlinux.armv8.intel_fpga/cxx/* ../ssd_detection_demo/Paddlelite/ -rf
	elif [ "$1" == "armv7hf" ];
	then
		./lite/tools/build_linux.sh --arch=armv7hf --with_extra=ON --with_log=ON --with_intel_fpga=ON --intel_fpga_sdk_root=../intelfpga_sdk full_publish
		cp build.lite.linux.armv7hf.gcc/inference_lite_lib.armlinux.armv7hf.intel_fpga/cxx/* ../ssd_detection_demo/Paddlelite/ -rf
	else
	echo "only suport armv7hf or armv8"
	exit
	fi
fi
