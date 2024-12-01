#!/bin/bash

TARGET_ARCH_ABI=armv8

# if [ -n "$1" ]; then
#     TARGET_ARCH_ABI=$1
# fi

if [ "$1" = "" ]
then
	echo "usage:./build.sh <ARCH_ABI(armv7hf or armv8)>"
	exit
else
	if [ "$1" = "armv8" ] || [ "$1" = "armv7hf" ];
	then
		TARGET_ARCH_ABI=$1
	else
		echo "only suport armv7hf or armv8"
		exit
	fi
fi

function readlinkf() {
    perl -MCwd -e 'print Cwd::abs_path shift' "$1";
}

rm -rf build
mkdir build
cd build
cmake -DTARGET_ARCH_ABI=${TARGET_ARCH_ABI} ..
make
cp libvnna.so ../
cp libvnna.so ../../../ssd_detection_demo/Paddlelite/lib/
