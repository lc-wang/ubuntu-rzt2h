#!/bin/bash
set -e

TOP=${PWD}
OUT_DIR=${TOP}/output
IMG=test.img
SIZE=8000M

# Bootloader
BL2_BP=${OUT_DIR}/trusted-firmware/trusted-firmware-rzt2h/build/t2h/release/bl2_bp_esd.bin
FIP=${OUT_DIR}/trusted-firmware/trusted-firmware-rzt2h/build/t2h/release/fip.bin

# Kernel & rootfs
ROOTFS_TGZ=${OUT_DIR}/rootfs.tgz
KERNEL_IMG=${OUT_DIR}/kernel/rz_linux/arch/arm64/boot/Image
DTB=${OUT_DIR}/kernel/rz_linux/arch/arm64/boot/dts/renesas/r9a09g077m44-dev.dtb
MODULES_DIR=${OUT_DIR}/kernel/rz_linux/modules/lib/modules

mkdir -p "${OUT_DIR}"

for f in "${BL2_BP}" "${FIP}" "${ROOTFS_TGZ}" "${KERNEL_IMG}" "${DTB}"; do
    if [ ! -f "$f" ]; then
        echo "[-] Missing file: $f"
        exit 1
    fi
done

echo "Remove old image ..."
rm -f "${IMG}"

echo "Create empty image ${IMG} (${SIZE}) ..."
truncate -s "${SIZE}" "${IMG}"

echo "Setup loop device ..."
LOOP_DEV=$(sudo losetup -f --show -P "${IMG}")
echo "LOOP_DEV = ${LOOP_DEV}"

cleanup() {
    set +e
    echo "Cleanup ..."
    sudo umount mnt 2>/dev/null || true
    rmdir mnt 2>/dev/null || true
    sudo losetup -d "${LOOP_DEV}" 2>/dev/null || true
}
trap cleanup EXIT

# 1. write into bootloader
############################################
# bl2_bp_esd.bin = BootParam×7 + BL2
# write into LBA 1：
#   LBA 1~7 : BootParam
#   LBA 8~  : BL2
echo "Write BL2_BP (BootParam+BL2) to LBA 1 ..."
sudo dd if="${BL2_BP}" of="${LOOP_DEV}" bs=512 seek=1 conv=notrunc status=none

# FIP LBA 768
echo "Write FIP to LBA 768 ..."
sudo dd if="${FIP}" of="${LOOP_DEV}" bs=512 seek=768 conv=notrunc status=none

# 2. Partition layout
############################################
# P1: start=4096, size=40434, type=0x0c (W95 FAT32 LBA)
# P2: start=44536, type=0x83 (Linux)

echo "Create partition table ..."
sudo sfdisk "${LOOP_DEV}" <<EOF
label: dos
unit: sectors

start=4096,  size=40434, type=c
start=44536,            type=83
EOF

echo "Re-read partition table ..."
sudo partprobe "${LOOP_DEV}"

# 3. Format partitions
############################################

echo "Format partitions ..."
sudo mkfs.vfat -F 32 "${LOOP_DEV}p1"
sudo mkfs.ext4 -F     "${LOOP_DEV}p2"

# 4. install rootfs / kernel / modules
############################################

mkdir -p mnt
echo "Mount rootfs partition ..."
sudo mount "${LOOP_DEV}p2" mnt

echo "Extract rootfs.tgz ..."
sudo tar zxpf "${ROOTFS_TGZ}" -C mnt

echo "Install kernel & dtb ..."
sudo mkdir -p mnt/boot
sudo cp "${KERNEL_IMG}" mnt/boot/
sudo cp "${DTB}"        mnt/boot/

echo "Install modules ..."
sudo mkdir -p mnt/lib/modules
sudo cp -rv "${MODULES_DIR}"/* mnt/lib/modules/

echo "Sync & unmount ..."
sync
sudo umount mnt
rmdir mnt

echo "Detach loop device ..."
sudo losetup -d "${LOOP_DEV}"

echo "Done. Image = ${IMG}"

