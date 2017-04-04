#!/bin/bash
ROOTDIR=$PWD
OUTPUTDIR=$ROOTDIR/output
IMAGEDIR=$ROOTDIR/output/images
UBOOTDIR=$ROOTDIR/output/build/uboot-odroid-v2015.10
function device_not_found_error () {
	echo "Given device not found!"
	echo "please check dmesg for verification"
}

function copy_bootloader_binaries () {
	cp $UBOOTDIR/sd_fuse/bl1.HardKernel $IMAGEDIR/
	cp $UBOOTDIR/sd_fuse/bl2.HardKernel $IMAGEDIR/
	cp $UBOOTDIR/sd_fuse/tzsw.HardKernel $IMAGEDIR/
	cp $UBOOTDIR/sd_fuse/sd_fusing.sh $IMAGEDIR/
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
	cd $IMAGEDIR
	sudo ./sd_fusing.sh /dev/$1
	sync
}

function copy_emmc_flashing_files () {
	cd $OUTPUTDIR
	sudo tar -cvzf images.tgz images
	sudo cp images.tgz /mnt/tmp/opt/
}

function flash_kernel_rootfs () {
	echo "partition found"
	sudo umount /dev/$11
	sudo mkfs.ext4 /dev/$11
	sudo mkdir -p /mnt/tmp
	sudo mount /dev/$11 /mnt/tmp
	sudo tar -xzvf $IMAGEDIR/ubuntu.tgz -C /mnt/tmp/
	sudo cp $IMAGEDIR/zImage  /mnt/tmp/zImage
	sudo cp $ROOTDIR/emmc_fusing.sh $IMAGEDIR/
	copy_emmc_flashing_files
	cd $ROOTDIR
	sync
	sudo umount /dev/$11
	sync
}

if [ -z $1 ]
then
	echo "usage:./prepare_sd.sh <SD Reader's device file>"
	echo "example: sdb, sdd, mmcblk0 etc"
	exit 0
else
	copy_bootloader_binaries
fi

if [ -b "/dev/$11" ]; then
	flash_kernel_rootfs $1
else
	echo "partition not found!"
	if [ -b "/dev/$1" ]; then
		create_partition $1
		flash_kernel_rootfs $1
	else
		device_not_found_error
	fi
fi

if [ -b "/dev/$1" ]; then
	flash_bootloder $1
	cd $ROOTDIR
	echo "SD card prepared"
	echo "Insert sd card into board and set board in SD card bootmode"
	echo "Power on board"
	echo "Good luck!"
else
	device_not_found_error
	exit 0
fi
