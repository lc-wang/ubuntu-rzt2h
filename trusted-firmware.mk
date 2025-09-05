######################################################################
#         2025 ARM64 Ubuntu/Debian Makefile - DO NOT EDIT            #
# Written by: Wig Cheng  <onlywig@gmail.com>                         #
######################################################################

include common.mk

ifeq ($(PLATFORM),rzt2h-evk)
$(eval TRUSTED_FIRMWARE_COMMIT  := deb68e75b6b73414317cd5b773470c033917e3e2)
$(eval TRUSTED_FIRMWARE_ARCHIVE := https://github.com/renesas-rz/rzg_trusted-firmware-a/archive/$(TRUSTED_FIRMWARE_COMMIT).tar.gz)
endif

all: build

clean:
	if test -d "$(TRUSTED_FIRMWARE_DIR)/trusted-firmware-rzt2h" ; then $(MAKE) -C $(TRUSTED_FIRMWARE_DIR)/trusted-firmware-rzt2h clean ; fi
	rm -rf $(wildcard $(TRUSTED_FIRMWARE_DIR))

distclean: clean
	rm -rf $(wildcard $(TRUSTED_FIRMWARE_DIR))

build: src
	$(MAKE) -C $(TRUSTED_FIRMWARE_DIR)/trusted-firmware-rzt2h PLAT=t2h BOARD=dev_1 PLATFORM_CORE_COUNT=4 BL33=$(UBOOT_DIR)/renesas-u-boot/u-boot.bin bl2 fip pkg

src:
	mkdir -p $(TRUSTED_FIRMWARE_DIR)
	if [ ! -f $(TRUSTED_FIRMWARE_DIR)/trusted-firmware-rzt2h/Makefile ] ; then \
		curl -L $(TRUSTED_FIRMWARE_ARCHIVE) | tar xz && \
		mv rzg_trusted-firmware-a* $(TRUSTED_FIRMWARE_DIR)/trusted-firmware-rzt2h ; \
	fi

.PHONY: build
