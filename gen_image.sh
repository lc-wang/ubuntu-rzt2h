#!/bin/bash

TOP=${PWD}

echo "target: --------------> $1"

echo "creating 6.5GiB empty image ..."
sudo dd if=/dev/zero of=test.img bs=1M count=6500

echo "created."

sudo kpartx -av test.img
loop_dev=$(losetup | grep "test.img" | awk  '{print $1}')
(echo "n"; echo "p"; echo; echo "16385"; echo "+64M"; echo "n"; echo "p"; echo; echo "147456"; echo ""; echo "a"; echo "1"; echo "w";) | sudo fdisk "$loop_dev"
sudo partprobe "$loop_dev"
sync

sudo mkfs.vfat -F 32 "$loop_dev"p1
sudo mkfs.ext4 "$loop_dev"p2

mkdir mnt

sudo mount "$loop_dev"p2 mnt
cd mnt
sudo tar zxvf ../output/rootfs.tgz
cd ${TOP}
sudo cp -rv ./output/kernel/rz_linux/arch/arm64/boot/Image mnt/boot/
sudo cp -rv ./output/kernel/rz_linux/arch/arm64/boot/dts/renesas/r9a09g077m44-dev.dtb mnt/boot/
sudo cp -rv ./output/kernel/rz_linux/modules/lib/modules/* mnt/lib/modules/

sudo umount mnt

if [[ "$1" == "rzt2h-evk" ]]; then
  bootloader_offset=768
fi
sudo dd if=./output/trusted-firmware/trusted-firmware-rzt2h/build/t2h/release/fip.bin of="$loop_dev" bs=1k seek="$bootloader_offset" conv=fsync
sync

rm -rf mnt

sudo kpartx -d test.img
