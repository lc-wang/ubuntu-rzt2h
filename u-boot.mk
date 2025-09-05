######################################################################
#         2025 ARM64 Ubuntu/Debian Makefile - DO NOT EDIT            #
# Written by: Wig Cheng  <onlywig@gmail.com>                         #
######################################################################

include common.mk

all: build

clean:
	if test -d "$(UBOOT_DIR)" ; then $(MAKE) ARCH=arm CROSS_COMPILE=${CC} -C $(UBOOT_DIR)/renesas-u-boot clean ; fi
	rm -f $(UBOOT_BIN)
	rm -rf $(wildcard $(UBOOT_DIR))

distclean: clean
	rm -rf $(wildcard $(UBOOT_DIR))

build:
ifeq ($(PLATFORM),rzt2h-evk)
	$(eval UBOOT_COMMIT := 0adf5cb2dbbe47d304f7276aa4000b1cc4575fe7)
	$(eval UBOOT_ARCHIVE := https://github.com/renesas-rz/renesas-u-boot-cip/archive/$(UBOOT_COMMIT).tar.gz)
	$(eval UBOOT_DEFCONFIG := rzt2h-dev_defconfig)
endif

	mkdir -p $(UBOOT_DIR)
	if [ ! -f $(UBOOT_DIR)/renesas-u-boot/Makefile ] ; then \
		curl -L $(UBOOT_ARCHIVE) | tar xz && \
		mv renesas-u-boot-cip-* $(UBOOT_DIR)/renesas-u-boot ; \
	fi

	$(MAKE) ARCH=arm CROSS_COMPILE=${CC} -C $(UBOOT_DIR)/renesas-u-boot $(UBOOT_DEFCONFIG)
	$(MAKE) ARCH=arm CROSS_COMPILE=${CC} -C $(UBOOT_DIR)/renesas-u-boot -j$(CPUS) all

u-boot: $(UBOOT_BIN)


.PHONY: build
