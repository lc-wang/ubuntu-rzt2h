######################################################################
#         2025 ARM64    Ubuntu/Debian Makefile - DO NOT EDIT         #
# Written by: Wig Cheng  <onlywig@gmail.com>                         #
######################################################################

ROOTFS_PACK := rootfs.tgz

DISTRO := noble
LANG := japanese

ifeq ($(PLATFORM),rzt2h-evk)
    TARGET := rzt2h-evk
else
    TARGET := unknown_target
    $(warning PLATFORM is not rzt2h-evk, TARGET set to $(TARGET))
endif

all: build

clean:
	rm -rf output/$(ROOTFS_PACK)
distclean: clean

build-rootfs: src
	@echo "PLATFORM: $(PLATFORM)"
	@echo "TARGET: $(TARGET)"
	@echo "DISTRO: $(DISTRO)"
	@echo "LANG: $(LANG)"
	@echo "build rootfs..."
	./gen_rootfs.sh $(TARGET) $(DISTRO) $(LANG)
	@mv $(ROOTFS_PACK) output/$(ROOTFS_PACK)

build: build-rootfs

src:
	if [ ! -d output ] ; then \
		mkdir -p output; \
	fi

.PHONY: all clean distclean build-rootfs build src
