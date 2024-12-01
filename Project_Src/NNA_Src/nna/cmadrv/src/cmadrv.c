#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/errno.h>
#include <linux/cdev.h>
#include <linux/delay.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/gfp.h>
#include <linux/jiffies.h>
#include <linux/module.h>
#include <linux/uaccess.h>
#include <linux/sched.h>
#include <linux/slab.h>
#include <linux/time.h> 
#include <linux/spinlock.h> 
#include <linux/platform_device.h>
#include <linux/completion.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>
#include <asm/io.h>
#include <asm/neon.h>
#include <asm/cacheflush.h>

#include "cmadrv.h"

/*-------------------------------------------------------------------------------------*/
/* Macros */


/*-------------------------------------------------------------------------------------*/

struct cma_pdata {
	/* character device */
	dev_t devno;
	struct cdev cdev;
	struct class* class;
	struct device* device;

	// DMA related
	struct dma_chan * chan;
	struct completion done;

	int pid; /* User process ID */
	struct task_struct *task;
	spinlock_t lock;
	struct mutex mutex; /* Access mutex */
};

// Locals
static struct cma_pdata *objId = NULL;

/*-------------------------------------------------------------------------------------*/

// DMA callback routine
static void cma_dma_callback( void* arg )
{
	struct cma_pdata *pdata = (struct cma_pdata *)arg;
	
	complete(&pdata->done);
}

static int cma_dma_init( struct cma_pdata* pdata )
{
	dma_cap_mask_t mask;
	
	dma_cap_zero(mask);
    dma_cap_set(DMA_MEMCPY, mask);
    pdata->chan = dma_request_channel(mask, 0, NULL);
    if (!pdata->chan) {
    	return -1;
    }
    
    return 0;
}

static void cma_dma_cleanup( struct cma_pdata* pdata )
{
    if (pdata->chan) {
    	dma_release_channel(pdata->chan);
    	pdata->chan = NULL;
    }
}

static int cma_dma_copy( struct cma_pdata* pdata, unsigned long dst, unsigned long src, size_t len )
{
    dma_cookie_t cookie;
    enum dma_ctrl_flags flags;
    struct dma_device *pdev;
    struct dma_async_tx_descriptor *tx;

    if (!pdata->chan) {
    	pr_info("^^^ Invalid DMA channel\n");
    	return -1;
    }
    pdev = pdata->chan->device;
    flags = DMA_CTRL_ACK | DMA_PREP_INTERRUPT;
    tx = pdev->device_prep_dma_memcpy(pdata->chan, dst, src, len, flags);
    if (!tx) {
    	pr_info("^^^ Failed to prepare memcpy\n");
		return -1;
    }
    init_completion(&pdata->done);
    tx->callback = cma_dma_callback;
    tx->callback_param = pdata;
    cookie = tx->tx_submit(tx);
    if (dma_submit_error(cookie)) {
        pr_info("^^^ Failed to do tx_submit\n");
        return -1;
    }
    dma_async_issue_pending(pdata->chan);
    wait_for_completion(&pdata->done);
    
    return 0;
}

/*-------------------------------------------------------------------------------------*/
/* File operations */

static int open(struct inode *inode, struct file *filp)
{
	struct cma_pdata *pdata;

	/* pointer to containing data structure of the character device inode */
	pdata = container_of(inode->i_cdev, struct cma_pdata, cdev);

	pdata->pid = current->pid;
	pdata->task = current;

	/* create a reference to our device state in the opened file */
	filp->private_data = pdata;

	return 0;
}

static int release(struct inode *inode, struct file *filp)
{
	return 0;
}

/* Memory map operation */
static int mmap(struct file *filp, struct vm_area_struct *vma)
{
	/* Maps to user-land address space according to phys */
    vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
    vma->vm_flags |= VM_IO;

	/* Map VM Zone to continuous physical pages */
    if (remap_pfn_range(vma, 
                        vma->vm_start, 
                        vma->vm_pgoff,
                        vma->vm_end - vma->vm_start, 
                        vma->vm_page_prot)) 
        return -EAGAIN;

    return 0;
}

static long ioctl( struct file *filp, unsigned int cmd, unsigned long arg )
{
	struct cma_pdata* pdata = (struct cma_pdata*)filp->private_data;
	struct cma_mcpy_s mcpy;
	struct cma_mblk_s mblk;
	int err = 0;

	if (!CMA_IOCTL_VALID(cmd)) {
		return -EINVAL;
	}
	switch (CMA_IOCTL_GET(cmd)) {
	case CMA_CMD_MCPY:
		if (copy_from_user(&mcpy, (void*)arg, sizeof(mcpy))) {
	        return -EFAULT;
	    }
	    if (mutex_lock_interruptible(&pdata->mutex)) {
	        return -ERESTARTSYS;
	    }
	    err = cma_dma_copy(pdata, (unsigned long)mcpy.dst, 
	    	(unsigned long)mcpy.src, mcpy.len);
	    mutex_unlock(&pdata->mutex);
	break;
	case CMA_CMD_MGET:
		if (copy_from_user(&mblk, (void*)arg, sizeof(mblk))) {
	        return -EFAULT;
	    }
	    mblk.virt = dma_alloc_coherent(NULL, mblk.size, (dma_addr_t*)&mblk.phys, GFP_KERNEL);
		if (mblk.virt==NULL) {
			return -ENOMEM;
		}
		mblk.phys = mblk.phys;
		mblk.size = mblk.size;
	    if (copy_to_user((void*)arg, &mblk, sizeof(mblk))) {
	    	dma_free_coherent(NULL, mblk.size, mblk.virt, (dma_addr_t)mblk.phys);
	        return -EFAULT;
	    }
	    if (copy_to_user((void*)arg, &mblk, sizeof(mblk))) {
	        return -EFAULT;
	    }
	break;
	case CMA_CMD_FREE:
		if (copy_from_user(&mblk, (void*)arg, sizeof(mblk))) {
	        return -EFAULT;
	    }
	    dma_free_coherent(NULL, mblk.size, mblk.virt, (dma_addr_t)mblk.phys);
	break;

	default: return -ENOTTY;
	}

	return err;
}

static struct file_operations fops = {
	.owner   = THIS_MODULE,
	.open    = open,
	.release = release,
	.mmap    = mmap,
	.unlocked_ioctl = ioctl,
};

/*-------------------------------------------------------------------------------------*/

static int __init cma_init( void )
{
	int err = 0;

	objId = kzalloc(sizeof(struct cma_pdata), GFP_KERNEL);
	if (!objId) {
		pr_err("^^^ kzalloc failed\n");
		return -ENOMEM;
	}
	
	// init dma
	err = cma_dma_init(objId);
	if (err<0) {
		pr_err("^^^ cma_dma_init failed\n");
		goto fail_1;
	}

	// Initialize character device
	err = alloc_chrdev_region(&objId->devno, 0, 1, CMA_DRVNAME);
	if (err<0) {
		pr_err("^^^ alloc_chrdev_region failed\n");
		goto fail_2;
	}
	objId->class = class_create(THIS_MODULE, CMA_BRDNAME);
	if (IS_ERR(objId->class)) {
		pr_err(KERN_ERR "^^^ class_create failed\n");
		goto fail_3;
	}
	cdev_init(&objId->cdev, &fops); 
	objId->cdev.owner = THIS_MODULE;
	objId->cdev.ops = &fops;
	err = cdev_add(&objId->cdev, objId->devno, 1);
	if (err) {
		pr_err("^^^ cdev_add failed\n");
		goto fail_4;
	}
	objId->device = device_create(objId->class, NULL, objId->devno, NULL, CMA_DRVNAME "%d", 0);
	if (IS_ERR(objId->device)) {
		pr_err("^^^ Can't create device\n");
		goto fail_5;
	}

	pr_info("^^^ CMA driver loading done.\n");
	
	mutex_init(&objId->mutex);
	spin_lock_init(&objId->lock);

	return 0;

// Error handling
fail_5:
	cdev_del(&objId->cdev);
fail_4:
	class_destroy(objId->class);
fail_3:
	unregister_chrdev_region(objId->devno, 1);
fail_2:
	cma_dma_cleanup(objId);
fail_1:
	kfree(objId);
	objId = NULL;

	return err;
}

static void __exit cma_exit(void)
{
	if (!objId) {
		return;
	}

	device_destroy(objId->class, objId->devno);
	class_destroy(objId->class);
	cdev_del(&objId->cdev);
	unregister_chrdev_region(objId->devno, 1);
	
	cma_dma_cleanup(objId);

	kfree(objId);
	objId = NULL;
	
	pr_err("^^^ CMA driver unloading done\n");
}

module_init(cma_init);
module_exit(cma_exit);
MODULE_LICENSE ("Dual BSD/GPL");

