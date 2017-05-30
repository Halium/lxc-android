#!/bin/sh

mount_android_partitions() {
    fstab=$1
    lxc_rootfs_path=$2
    cat ${fstab} | while read line; do
        set -- $line
        # Skip any unwanted entry
        echo $1 | egrep -q "^#" && continue
        ([ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]) && continue
        ([ "$3" = "emmc" ] || [ "$3" = "swap" ] || [ "$3" = "mtd" ]) && continue
        [ ! -d "$2" ] && continue

        mkdir -p ${lxc_rootfs_path}/$2
        mount -n -o bind,recurse $2 ${lxc_rootfs_path}/$2
	done
}

INITRD=/system/boot/android-ramdisk.img
rm -Rf $LXC_ROOTFS_PATH
mkdir -p $LXC_ROOTFS_PATH
cd $LXC_ROOTFS_PATH
cat $INITRD | gzip -d | cpio -i

mknod -m 666 $LXC_ROOTFS_PATH/dev/null c 1 3

# Create /dev/pts if missing
mkdir -p $LXC_ROOTFS_PATH/dev/pts

# Pass /sockets through
mkdir -p /dev/socket $LXC_ROOTFS_PATH/socket
mount -n -o bind,rw /dev/socket $LXC_ROOTFS_PATH/socket

rm $LXC_ROOTFS_PATH/sbin/adbd

# Mount the android partitions
mount_android_partitions $LXC_ROOTFS_PATH/fstab* "$LXC_ROOTFS_PATH"

sed -i '/on early-init/a \    mkdir /dev/socket\n\    mount none /socket /dev/socket bind' $LXC_ROOTFS_PATH/init.rc

sed -i "/mount_all /d" $LXC_ROOTFS_PATH/init.*.rc
sed -i "/on nonencrypted/d" $LXC_ROOTFS_PATH/init.rc

rm -Rf $LXC_ROOTFS_PATH/vendor
ln -s /system/vendor $LXC_ROOTFS_PATH/vendor
