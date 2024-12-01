/* Copyright (c) 2020 AWCloud. All Rights Reserved.
// Copyright (c) 2020 AWCloud. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#ifndef _CMADRV_H_
#define _CMADRV_H_

// Version
#define CMA_VERSION 0x01000000

// Board name
#define CMA_BRDNAME "c5soc"
#define CMA_DRVNAME "cmadrv"

// Memory block
struct cma_mblk_s {
	void* addr; // base address
	void* virt; // kernel address
	unsigned long phys; // Pysical address
	size_t size; // size in bytes
};

// Memory copy
struct cma_mcpy_s {
	unsigned long dst; // DST address
	unsigned long src; // SRC address
	size_t        len; // size in bytes
};

#define CMA_MAGIC_ID (('C' + 'M' + 'A' + 'B') / 4)

/* Ioctls */
#define CMA_IOCTL_MAKE(cmd)  ( _IO( CMA_MAGIC_ID, cmd))
#define CMA_IOCTL_GET(cmd)   ( _IOC_NR(cmd))
#define CMA_IOCTL_VALID(cmd) ((_IOC_TYPE(cmd)==CMA_MAGIC_ID) ? 1 : 0)

#define CMA_CMD_MGET       0x00 // struct cma_blk_s
#define CMA_CMD_FREE       0x01 // struct cma_blk_s

#define CMA_CMD_MCPY       0x10 // struct cma_cpy_s

#endif

