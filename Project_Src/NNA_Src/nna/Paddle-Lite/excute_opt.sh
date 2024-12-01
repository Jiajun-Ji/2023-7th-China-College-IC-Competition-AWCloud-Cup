#!/bin/bash
if [ "$1" = "" ]
then
	echo "usage:./excute_opt.sh awcloud <modle path> <nbfile path>"
else
	./build.opt/lite/api/opt --model_dir=$1 --valid_targets=intel_fpga,arm --optimize_out_type=naive_buffer --optimize_out=$2
fi

