######################################################################
#         2025 ARM64 Ubuntu/Debian Makefile - DO NOT EDIT          #
# Written by: Wig Cheng  <onlywig@gmail.com>                       #
######################################################################

BUILD_STEPS := u-boot trusted-firmware kernel rootfs image

all: build

pre-u-boot:
pre-trusted-firmware:
pre-kernel:
pre-rootfs:
pre-image:

define BUILD_STEPS_TEMPLATE
build-$(1): pre-$(1)
	$$(MAKE) -f $(1).mk build
clean-$(1):
	$$(MAKE) -f $(1).mk clean
distclean-$(1):
	$$(MAKE) -f $(1).mk distclean
.PHONY: pre-$(1) build-$(1) clean-$(1) distclean-$(1)
endef

$(foreach step,$(BUILD_STEPS),$(eval $(call BUILD_STEPS_TEMPLATE,$(step))))

build: $(addprefix build-,$(BUILD_STEPS))

clean: $(addprefix clean-,$(BUILD_STEPS))

distclean: $(addprefix distclean-,$(BUILD_STEPS))

u-boot: build-u-boot

trusted-firmware: build-trusted-firmware

kernel: build-kernel

rootfs: build-rootfs

image: build-image

.PHONY: all build clean distclean u-boot trusted-firmware kernel rootfs
