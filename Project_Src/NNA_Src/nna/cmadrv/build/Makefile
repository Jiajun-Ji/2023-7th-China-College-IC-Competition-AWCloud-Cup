# Kernel Module Make File

# Kernel source tree
#KSRC_DIR := $(BASE_DIR)/build/tmp/work/plnx_zynq7-xilinx-linux-gnueabi/linux-xlnx/4.19-xilinx-v2019.1+gitAUTOINC+9811303824-r0/linux-plnx_zynq7-standard-build
# KSRC_DIR:=/home/fmsh/work/bsp-20220223-inc-patches/FMQL-Linux-SDK-Prj-20220223/linux-4.14.55-fmsh
KSRC_DIR:=/home/bananasuper/work/software/linux-4.9.78

# Architecture and cross compile
ARCH := arm
CROSS_COMPILE := arm-linux-gnueabihf-

ifneq ($(KERNELRELEASE),)
# call from kernel build system

# Extra C compile flags
EXTRA_CFLAGS += -O3 -I$(M)/../inc

# Object file(s) to build kernel module, more dependency objects may included.
DRV_OBJS := ../src/cmadrv.o

cmadrv-objs := $(DRV_OBJS)

obj-m := cmadrv.o

else

PWD     := $(shell pwd)
SUBDIRS := build src

# Normal Makefile
all:
	@$(MAKE) -s -C $(KSRC_DIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

endif

# Cleanup your generated files
clean:
	for i in $(SUBDIRS) ; do cd ../$$i; rm -rf *.ko *.o *~ core .depend .*.cmd *.mod.c .tmp_versions; cd -; done

depend:

.PHONY : all clean

# End of file

