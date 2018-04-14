#!/bin/sh


if [ -f "/tmp/lxc_android_once" ]; then
    echo "lxc:android contianer had already been invoked.";
    exit -255
fi
touch /tmp/lxc_android_once

for mountpoint in /android/*; do
	mount_name=`basename $mountpoint`
	desired_mount=$LXC_ROOTFS_PATH/$mount_name

	# Remove symlinks, for example bullhead has /vendor -> /system/vendor
	[ -L $desired_mount ] && rm $desired_mount

	[ -d $desired_mount ] || mkdir $desired_mount
	mount --bind $mountpoint $desired_mount
done

mknod -m 666 $LXC_ROOTFS_PATH/dev/null c 1 3

# Create /dev/pts if missing
mkdir -p $LXC_ROOTFS_PATH/dev/pts

# Pass /sockets through
mkdir -p /dev/socket $LXC_ROOTFS_PATH/socket
mount -n -o bind,rw /dev/socket $LXC_ROOTFS_PATH/socket

sed -i '/on early-init/a \    mkdir /dev/socket\n\    mount none /socket /dev/socket bind' $LXC_ROOTFS_PATH/init.rc

sed -i "/mount_all /d" $LXC_ROOTFS_PATH/init.*.rc
sed -i "/swapon_all /d" $LXC_ROOTFS_PATH/init.*.rc
sed -i "/on nonencrypted/d" $LXC_ROOTFS_PATH/init.rc

# Config snippet scripts
run-parts /var/lib/lxc/android/pre-start.d || true
