#!/bin/bash

# configure
#export PATH=/home/lyq/project/haiyun3.0/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:$PATH
TARGET_ARCH_ABI=armv8 # for Cyclone V SoC
DETECTION_TARGET=picture
CAMERA_TYPE=ucam
PADDLE_LITE_DIR=../Paddlelite

# if [ "x$1" != "x" ]; then
#     TARGET_ARCH_ABI=$1
# else
# 	echo "usage:./build.sh <ARCH_ABI(armv7hf or armv8)>"
# fi

if [ "$1" = "" ]
then
	echo "usage:./build.sh <ARCH_ABI(armv7hf or armv8)>"
	exit
else
	if [ "$1" = "armv8" ] || [ "$1" = "armv7hf" ];
	then
		TARGET_ARCH_ABI=$1
        # echo "ARCH: " {$TARGET_ARCH_ABI}
		if [ "$2" = "camera" ];
		then
			DETECTION_TARGET=$2
            # echo "TARGET: " {$DETECTION_TARGET}
            if [ "$3" = "aiep" ];
            then
                CAMERA_TYPE=$3
                # echo "TYPE: " {$CAMERA_TYPE}
            fi
		fi
	else
		echo "only suport armv7hf or armv8"
		exit
	fi
fi

# build
rm -rf build
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DLITE_WITE_PROFILE=1 -DPADDLE_LITE_DIR=${PADDLE_LITE_DIR} -DDETECTION_TARGET=${DETECTION_TARGET} -DCAMERA_TYPE=${CAMERA_TYPE} -DTARGET_ARCH_ABI=${TARGET_ARCH_ABI} -DCMAKE_PREFIX_PATH=../Paddlelite/lib .. 
make
