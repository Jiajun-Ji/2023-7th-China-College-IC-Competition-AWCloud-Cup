#include <linux/init.h>
#include <linux/module.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <asm/io.h>
#include <linux/ioport.h>
#include <linux/cdev.h>
#include <linux/slab.h>
#include <asm/uaccess.h>
#include <linux/dma-mapping.h>


#define AMM_WR_MAGIC 'x'
#define AMM_WR_CMD_DMA_BASE  _IOR(AMM_WR_MAGIC,0x1a,int)

static int major;	
static int minor;	
struct cdev *amm_wr; 
static dev_t devno; 
static struct class *amm_wr_class;


void *my_kernel_buffer=NULL;	
unsigned long my_kernel_buffer_phy;	

static int dma_size=(1024*768*3);


module_param(dma_size, int, S_IRUGO);


int amm_wr_open( struct inode *node, struct file *filp )
{
	return 0;
}


int amm_wr_release( struct inode *node, struct file *filp )
{
	return 0;
}


ssize_t amm_wr_write(struct file *filp, const char __user *buf, size_t count, loff_t *f_pos)
{
	/*拷贝数据到用户空间*/
	if (copy_from_user(my_kernel_buffer, buf, count))
	{
		count = -EFAULT;
		goto out;
	}
out:
	return count;
}


ssize_t amm_wr_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos)
{
	
	if (copy_to_user(buf, my_kernel_buffer, count))
	{
		count = -EFAULT;
		goto out;
	}
out:
	return count;
}


static long amm_wr_ioctl( struct file *filp, unsigned int cmd, unsigned long arg)
{
	int ret = 0;
	unsigned int data;	
	switch (cmd)
	{
	case AMM_WR_CMD_DMA_BASE:
	{
		data = my_kernel_buffer_phy;	
		if(put_user(data, (unsigned int *)arg))
		{
			printk(KERN_ERR "put user err\n");
			ret = -EINVAL;
		}
		break;
	}
	default:
		printk(KERN_ERR "invalid value\n");
		ret = -EINVAL;
		break;
	}
	return ret;
}


static  struct file_operations amm_wr_fops =
{
	.owner = 			THIS_MODULE,
	.open = 			amm_wr_open,
	.release = 			amm_wr_release,
	.unlocked_ioctl = 		amm_wr_ioctl,
	.read=				amm_wr_read,
	.write=				amm_wr_write,
};


static int __init amm_wr_init(void)
{
	int ret;	
	
	ret = alloc_chrdev_region(&devno, minor, 1, "amm_wr");
	major = MAJOR(devno);
	if (ret < 0)
	{
		printk(KERN_ERR "cannot get major %d \n", major);
		return -1;
	}

	printk (KERN_ERR "my module loading...\n");
	
	my_kernel_buffer = dma_alloc_coherent(NULL,dma_size,(void *)&(my_kernel_buffer_phy),GFP_KERNEL);
	if(!my_kernel_buffer)
	{
		pr_info("alloc buffer1 memory failed \n");
		goto fail_malloc;
	}
	printk(KERN_ERR "buffer1 virtual address 0x%08x\n", (uint32_t)(my_kernel_buffer));
	printk(KERN_ERR "buffer1 physical address 0x%08x-0x%08x\n", (uint32_t)my_kernel_buffer_phy, virt_to_phys(my_kernel_buffer));

	amm_wr = cdev_alloc(); 
	if (amm_wr != NULL)
	{
		cdev_init(amm_wr, &amm_wr_fops); 
		amm_wr->owner = THIS_MODULE;
		if (cdev_add(amm_wr, devno, 1) != 0)
		{
			printk(KERN_ERR "add cdev error!\n");
			goto error;
		}
	}
	else
	{
		printk(KERN_ERR "cdev_alloc error!\n");
		return -1;
	}
	
	amm_wr_class = class_create(THIS_MODULE, "amm_wr_class");
	if (IS_ERR(amm_wr_class))
	{
		printk(KERN_ERR "create class error\n");
		return -1;
	}
	
	device_create(amm_wr_class, NULL, devno, NULL, "amm_wr");
	return 0;

error:	
	dma_free_coherent(NULL,dma_size,my_kernel_buffer,my_kernel_buffer_phy);
fail_malloc:	
	unregister_chrdev_region(devno, 1);

	return ret;
}

static void __exit amm_wr_exit(void)
{
	cdev_del(amm_wr);
	unregister_chrdev_region(devno, 1); 
	device_destroy(amm_wr_class, devno);
	class_destroy(amm_wr_class);
	
	dma_free_coherent(NULL,dma_size,my_kernel_buffer,my_kernel_buffer_phy);
	printk(KERN_ERR  "module exit\n");
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("zc");

module_init(amm_wr_init);
module_exit(amm_wr_exit);
