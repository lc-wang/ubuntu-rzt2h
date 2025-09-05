######################################################################
#         2025 ARM64 Ubuntu/Debian Makefile - DO NOT EDIT            #
# Written by: Wig Cheng  <onlywig@gmail.com>                         #
######################################################################

include common.mk

ifeq ($(PLATFORM),rzt2h-evk)
KERNEL_DEFCONFIG := defconfig
$(eval KERNEL_COMMIT  := 1c5832cafd2fe0ab967212552ffe013ab187705e)
$(eval KERNEL_ARCHIVE := https://github.com/renesas-rz/rz_linux-cip/archive/$(KERNEL_COMMIT).tar.gz)
$(eval ARCH := arm64)
endif

all: build

clean:
	if test -d "$(KERNEL_DIR)/rz_linux" ; then $(MAKE) ARCH=${ARCH} CROSS_COMPILE=${CC} -C $(KERNEL_DIR)/rz_linux clean ; fi
	rm -f $(KERNEL_BIN)
	rm -rf $(wildcard $(KERNEL_DIR))

distclean: clean
	rm -rf $(wildcard $(KERNEL_DIR))

build: src
	$(MAKE) ARCH=${ARCH} CROSS_COMPILE=${CC} -C $(KERNEL_DIR)/rz_linux $(KERNEL_DEFCONFIG)
	$(MAKE) ARCH=${ARCH} CROSS_COMPILE=${CC} -C $(KERNEL_DIR)/rz_linux -j$(CPUS) all
	$(MAKE) ARCH=${ARCH} CROSS_COMPILE=${CC} -C $(KERNEL_DIR)/rz_linux -j$(CPUS) dtbs
	$(MAKE) ARCH=${ARCH} CROSS_COMPILE=${CC} -C $(KERNEL_DIR)/rz_linux -j$(CPUS) modules
	$(MAKE) ARCH=${ARCH} CROSS_COMPILE=${CC} -C $(KERNEL_DIR)/rz_linux -j$(CPUS) modules_install INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=$(KERNEL_DIR)/rz_linux/modules/

src:
	mkdir -p $(KERNEL_DIR)
	if [ ! -f $(KERNEL_DIR)/rz_linux/Makefile ] ; then \
		curl -L $(KERNEL_ARCHIVE) | tar xz && \
		mv rz_linux-cip* $(KERNEL_DIR)/rz_linux ; \
	fi


.PHONY: build
