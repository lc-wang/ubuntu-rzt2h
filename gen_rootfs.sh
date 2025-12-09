#!/bin/bash
# Author: Wig Cheng <onlywig@gmail.com>
# Date: 12/11/2024

TOP=${PWD}

ARCH=arm64
QEMU=qemu-aarch64-static
QEMU_FILE="qemu_install.sh"
BASE_ROOTFS_TAR=${TOP}/rootfs-base.tgz

# Set PLATFORM from 1st argument, default to "rzt2h-evk" if not provided
PLATFORM=${1:-rzt2h-evk}

# Set DISTRO from the 2nd argument, default to "noble" if not provided
DISTRO=${2:-noble}
# Set LANGUAGE from the 3rd argument, default to "C" if not provided
LANGUAGE=${3:-C}

# generate rootfs
gen_pure_rootfs() {

  bootstrap_rootfs
  customize_rootfs
  package_rootfs
}

bootstrap_rootfs() {

  if [ -d "rootfs" ]; then
    echo "reuse existing rootfs directory"
    sudo cp /usr/bin/"$QEMU" ${TOP}/rootfs/usr/bin
    return
  fi

  if [ -f "${BASE_ROOTFS_TAR}" ]; then
    echo "extract cached base rootfs from ${BASE_ROOTFS_TAR}"
    mkdir rootfs
    sudo tar --numeric-owner -xpf "${BASE_ROOTFS_TAR}" -C ${TOP}/rootfs
    sudo cp /usr/bin/"$QEMU" ${TOP}/rootfs/usr/bin
    return
  fi

  mkdir rootfs
  echo "generate ubuntu rootfs... default version: nodle LTS"

  sudo debootstrap --arch="$ARCH" --keyring=/usr/share/keyrings/ubuntu-archive-keyring.gpg --verbose --foreign $DISTRO ${TOP}/rootfs
  sudo cp /usr/bin/"$QEMU" ${TOP}/rootfs/usr/bin
  sudo LANG=C chroot ${TOP}/rootfs /debootstrap/debootstrap --second-stage

  echo "cache base rootfs to ${BASE_ROOTFS_TAR}"
  sudo tar --numeric-owner -czpf "${BASE_ROOTFS_TAR}" -C ${TOP}/rootfs .
}

customize_rootfs() {

  if [[ $PLATFORM == "rzt2h-evk" ]]; then
    # growpart
    sudo cp -a ${TOP}/libs_overlay/bin/tn-growpart-helper ${TOP}/rootfs/usr/sbin/
    QEMU_FILE="qemu_install.sh"
  fi

  sudo cp ${TOP}/${QEMU_FILE} ${TOP}/rootfs/usr/bin/
  sudo LANG=C chroot ${TOP}/rootfs /bin/bash -c "chmod a+x /usr/bin/${QEMU_FILE}; /usr/bin/${QEMU_FILE} $PLATFORM $DISTRO $LANGUAGE"
  sync
  sudo rm -rf ${TOP}/rootfs/usr/bin/${QEMU_FILE}
}

package_rootfs() {

  cd ${TOP}/rootfs
  sudo tar --exclude='./dev/*' --exclude='./lost+found' --exclude='./mnt/*' --exclude='./media/*' --exclude='./proc/*' --exclude='./run/*' --exclude='./sys/*' --exclude='./tmp/*' --numeric-owner -czpvf ../rootfs.tgz .
  cd ${TOP}
}

gen_pure_rootfs "$1"
