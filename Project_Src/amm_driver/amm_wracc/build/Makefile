# Kernel Module Make File

# Kernel source tree
KSRC_DIR := /opt/software/linux-4.9.78

# Architecture and cross compile
ARCH := arm
CROSS_COMPILE := /opt/software/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-

ifneq ($(KERNELRELEASE),)
# call from kernel build system

# Extra C compile flags
EXTRA_CFLAGS += -I$(M)/../inc

# Object file(s) to build kernel module, more dependency objects may included.
DRV_OBJS := ../src/amm_wr_drv.o
DRV_OBJS += 

amm_wr_drv-objs := $(DRV_OBJS)

obj-m := amm_wr_drv.o

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

