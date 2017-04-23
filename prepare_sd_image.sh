#!/bin/bash
. setup_env

function device_not_found_error () {
	echo "Given device not found!"
	echo "please check dmesg for verification"
}

function create_partition () {
	sudo fdisk /dev/$1 <<END
	n
	p



	w
	q
END
}

function flash_bootloder () {
	cd $IMAGES_DIR
	sudo ./sd_fusing.sh /dev/$1
	sync
}

function flash_kernel_rootfs () {
	echo "partition found"
	sudo umount /dev/$1p1
	sudo mkfs.ext4 /dev/$1p1
	sudo mkdir -p /mnt/tmp
	sudo mount /dev/$1p1 /mnt/tmp
	sudo tar -xzvf $IMAGES_DIR/ubuntu.tgz -C /mnt/tmp/
	sudo cp $IMAGES_DIR/zImage  /mnt/tmp/zImage
	cd $ROOT_DIR
	sync
	sudo umount /dev/$1p1
	sync
}

function create_sd_image () {
	sudo dd if=/dev/zero of=ubuntu_sd.img bs=100M count=50
	losetup -f ubuntu_sd.img
	losetup -a
}

if [ -z $1 ]
then
	echo "usage:./prepare_sd_image.sh <SD Reader's device file>"
	echo "example: sdb, sdd, mmcblk0 etc"
	exit 0
else
	cd $IMAGES_DIR
	create_sd_image
	create_partition loop0
fi

if [ -b "/dev/loop0p1" ]; then
	flash_kernel_rootfs loop0
else
	echo "partition not found!"

fi

if [ -b "/dev/loop0" ]; then
	flash_bootloder loop0
	cd $IMAGES_DIR
	sudo dd if=ubuntu_sd.img of=/dev/$1 bs=1M conv=fsync
	sync
	losetup -d /dev/loop0
	echo "SD card prepared"
	echo "Insert sd card into board and set board in SD card bootmode"
	echo "Power on board"
	echo "Good luck!"
else
	device_not_found_error
	exit 0
fi
