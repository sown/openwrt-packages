# SOWN-at-Home Build File
#
# Build Options
#

OPENWRT_RELEASE ?= 22.03.0
OPENWRT_TARGET ?= ath79
OPENWRT_FLASH_LAYOUT ?= generic
OPENWRT_PROFILE ?= glinet_gl-ar150

SOWN_PACKAGES := sown-core
PACKAGES := -wpad-mini -dnsmasq -firewall

ifneq (,$(filter glinet_gl-ar150,$(OPENWRT_PROFILE)))
  SOWN_PACKAGES += sown-leds-ar150
endif

PACKAGES += $(SOWN_PACKAGES)

# OpenWRT Source
#
# Note that the first part of the variable name is lower case.

OPENWRT_DOWNLOAD_URL := https://downloads.openwrt.org/releases

OPENWRT_FOLDER_URL = $(OPENWRT_DOWNLOAD_URL)/$(OPENWRT_RELEASE)/targets/$(OPENWRT_TARGET)/$(OPENWRT_FLASH_LAYOUT)

imagebuilder_URL := $(OPENWRT_FOLDER_URL)/openwrt-imagebuilder-$(OPENWRT_RELEASE)-$(OPENWRT_TARGET)-$(OPENWRT_FLASH_LAYOUT).Linux-x86_64.tar.xz
sdk_URL := $(OPENWRT_FOLDER_URL)/openwrt-sdk-$(OPENWRT_RELEASE)-$(OPENWRT_TARGET)-$(OPENWRT_FLASH_LAYOUT)_gcc-11.2.0_musl.Linux-x86_64.tar.xz

# Directories
ROOT_DIR = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR = $(ROOT_DIR)/build
DOWNLOADS_DIR = $(BUILD_DIR)/downloads
SOURCES_DIR = $(BUILD_DIR)/sources

# Downloading and Extracting
$(DOWNLOADS_DIR):
	mkdir -p $@ 

$(DOWNLOADS_DIR)/%.tar.xz: $(DOWNLOADS_DIR)
	wget $($(basename $(basename $(notdir $@)))_URL) -O $@

$(SOURCES_DIR)/%: $(DOWNLOADS_DIR)/%.tar.xz
	mkdir -p $@
	tar -xf $< -C $@ --strip 1 

# Building Packages

$(SOURCES_DIR)/sdk/feeds.conf.default: $(SOURCES_DIR)/sdk
	echo "src-link sown $(ROOT_DIR)/packages" >> $@

update_feeds: $(SOURCES_DIR)/sdk/feeds.conf.default
	$(SOURCES_DIR)/sdk/scripts/feeds update sown

install-%:
	$(SOURCES_DIR)/sdk/scripts/feeds install $* 

config_packages: update_feeds $(addprefix install-, $(SOWN_PACKAGES)) 
	make -C $(SOURCES_DIR)/sdk defconfig
	echo "CONFIG_SIGNED_PACKAGES=n" >> $(SOURCES_DIR)/sdk/.config

compile-%: update_feeds install-%
	make -C $(SOURCES_DIR)/sdk package/$*/compile

packages: config_packages $(addprefix compile-, $(SOWN_PACKAGES))
	make -C $(SOURCES_DIR)/sdk package/index

$(SOURCES_DIR)/imagebuilder/files: $(ROOT_DIR)/files $(SOURCES_DIR)/imagebuilder
	ln -fTs $< $@

$(SOURCES_DIR)/imagebuilder/repositories.conf: packages
	echo "src sown file:/$(SOURCES_DIR)/sdk/bin/packages/mips_24kc/sown/" >> $@ 

imagebuilder-packages:
	cp $(SOURCES_DIR)/sdk/bin/packages/mips_24kc/sown/*.ipk $(SOURCES_DIR)/imagebuilder/packages/

firmware: $(SOURCES_DIR)/imagebuilder $(SOURCES_DIR)/imagebuilder/files imagebuilder-packages
	make -C $(SOURCES_DIR)/imagebuilder image PROFILE=$(OPENWRT_PROFILE) PACKAGES="$(PACKAGES)" FILES=files/

.PHONY: all clean firmware packages update_feeds install-% compile-% 

.DEFAULT_GOAL := all

all: firmware

clean:
	git clean -fdX
