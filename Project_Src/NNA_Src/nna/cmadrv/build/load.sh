#!/bin/sh

module="cmem"

./unload.sh 2>/dev/null

# invoke insmod with all arguments we got
insmod ./$module.ko || exit 1

if [ ! -f /dev/${module} ]
then
    major=$(awk '$2=="cmem" {print $1}' /proc/devices)
    mknod /dev/${module} c ${major} 0
fi

