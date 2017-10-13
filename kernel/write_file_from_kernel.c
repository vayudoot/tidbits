#include <linux/fs.h>
#include <asm/segment.h>
#include <asm/uaccess.h>
#include <linux/buffer_head.h>

struct file *
driver_file_open(const char *path, int flags, int mode)
{
        struct file *filp = NULL;
        mm_segment_t    oldfs;
        oldfs   = get_fs();
        set_fs(get_ds());
        filp = filp_open(path, O_CREAT|O_RDWR, S_IRWXU|S_IRWXG|S_IRWXO);
        set_fs(oldfs);
        return (filp);
}



void
driver_file_close(struct file *filp)
{
        filp_close(filp, NULL);
}



int
driver_file_write(struct file *file, unsigned long long offset, unsigned char *data, unsigned int size)
{
        int     ret;
        mm_segment_t    oldfs;
        loff_t  pos = offset;
        oldfs   = get_fs();
        set_fs(get_ds());

        //vfs_setpos(file, pos, pos + PAGE_SIZE);
        //Workaround for vfs_setpos, not implemented on my version of linux.
        spin_lock(&file->f_lock);
        file->f_pos = pos;
        //file->f_version = 0;
        printk(KERN_INFO "set position to  %llx\n", pos);
        spin_unlock(&file->f_lock);


        ret = vfs_write(file, data, size, &pos);
        //vfs_fsync(file, 0);
        set_fs(oldfs);
        return (ret);
}




int
driver_file_read(struct file *file, unsigned long long offset, unsigned char *data, unsigned int size)
{
        int     ret;
        mm_segment_t    oldfs;
        loff_t  pos = offset;
        oldfs   = get_fs();
        set_fs(get_ds());

        //vfs_setpos(file, pos, pos + PAGE_SIZE);
        //Workaround for vfs_setpos, not implemented on my version of linux.
        spin_lock(&file->f_lock);
        file->f_pos = pos;
        //file->f_version = 0;
        printk(KERN_INFO "set position to read %llx\n", pos);
        spin_unlock(&file->f_lock);


        ret = vfs_read(file, data, size, &pos);
        //vfs_fsync(file, 0);
        set_fs(oldfs);
        return (ret);
}

