######################################################################
#         2025 ARM64 Ubuntu/Debian Makefile - DO NOT EDIT            #
# Written by: Wig Cheng  <onlywig@gmail.com>                         #
######################################################################

include common.mk

DEFAULT_IMAGE := ubuntu.img

all: build

clean:
	rm -rf $(OUTPUT_DIR)/$(DEFAULT_IMAGE)
distclean: clean

build-image:
ifeq ($(PLATFORM),rzt2h-evk)
	$(eval TARGET := rzt2h-evk)
endif

	@echo "image generating..."
	sudo ./gen_image.sh $(TARGET)
	@sudo mv test.img $(OUTPUT_DIR)/$(DEFAULT_IMAGE)

build: build-image

.PHONY: build-image build
