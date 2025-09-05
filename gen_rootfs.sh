#!/bin/bash
# Author: Wig Cheng <onlywig@gmail.com>
# Date: 12/11/2024

TOP=${PWD}

# Set PLATFORM from 1st argument, default to "rzt2h-evk" if not provided
PLATFORM=${1:-rzt2h-evk}

# Set DISTRO from the 2nd argument, default to "noble" if not provided
DISTRO=${2:-noble}
# Set LANGUAGE from the 3rd argument, default to "C" if not provided
LANGUAGE=${3:-C}

# generate rootfs
gen_pure_rootfs() {

  ARCH=arm64
  QEMU=qemu-aarch64-static

  if [ -d "rootfs" ]; then
    sudo cp /usr/bin/"$QEMU" ${TOP}/rootfs/usr/bin
  else
    mkdir rootfs
    echo "generate ubuntu rootfs... default version: nodle LTS"

    sudo debootstrap --arch="$ARCH" --keyring=/usr/share/keyrings/ubuntu-archive-keyring.gpg --verbose --foreign $DISTRO ${TOP}/rootfs
    sudo cp /usr/bin/"$QEMU" ${TOP}/rootfs/usr/bin
    sudo LANG=C chroot ${TOP}/rootfs /debootstrap/debootstrap --second-stage
  fi

  if [[ $PLATFORM == "rzt2h-evk" ]]; then
    # growpart
    sudo cp -a ${TOP}/libs_overlay/bin/tn-growpart-helper ${TOP}/rootfs/usr/sbin/
    QEMU_FILE="qemu_install.sh"
  fi

  sudo cp ${TOP}/${QEMU_FILE} ${TOP}/rootfs/usr/bin/
  sudo LANG=C chroot ${TOP}/rootfs /bin/bash -c "chmod a+x /usr/bin/${QEMU_FILE}; /usr/bin/${QEMU_FILE} $PLATFORM $DISTRO $LANGUAGE"
  sync
  sudo rm -rf ${TOP}/rootfs/usr/bin/${QEMU_FILE}

  cd ${TOP}/rootfs
  sudo tar --exclude='./dev/*' --exclude='./lost+found' --exclude='./mnt/*' --exclude='./media/*' --exclude='./proc/*' --exclude='./run/*' --exclude='./sys/*' --exclude='./tmp/*' --numeric-owner -czpvf ../rootfs.tgz .
  cd ${TOP}
}

gen_pure_rootfs "$1"
