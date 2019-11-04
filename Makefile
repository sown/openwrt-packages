sdk_URL = "https://downloads.openwrt.org/releases/18.06.4/targets/ar71xx/generic/openwrt-sdk-18.06.4-ar71xx-generic_gcc-7.3.0_musl.Linux-x86_64.tar.xz" 
imagebuilder_URL = "https://downloads.openwrt.org/releases/18.06.4/targets/ar71xx/generic/openwrt-imagebuilder-18.06.4-ar71xx-generic.Linux-x86_64.tar.xz"

ROOT_DIR = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR = $(ROOT_DIR)/build
DOWNLOADS_DIR = $(BUILD_DIR)/downloads
SOURCES_DIR = $(BUILD_DIR)/sources

$(DOWNLOADS_DIR):
	mkdir -p $@ 

$(DOWNLOADS_DIR)/%.tar.xz: $(DOWNLOADS_DIR)
	wget $($(basename $(basename $(notdir $@)))_URL) -O $@

$(SOURCES_DIR)/%: $(DOWNLOADS_DIR)/%.tar.xz
	mkdir -p $@
	tar -xf $< -C $@ --strip 1 

packages: $(SOURCES_DIR)/sdk 
	grep sown $(SOURCES_DIR)/sdk/feeds.conf.default || echo "src-link sown $(ROOT_DIR)" >> $(SOURCES_DIR)/sdk/feeds.conf.default
	$(SOURCES_DIR)/sdk/scripts/feeds update sown
	$(SOURCES_DIR)/sdk/scripts/feeds install sown-core
	$(SOURCES_DIR)/sdk/scripts/feeds install sown-leds-ar150
	echo "CONFIG_SIGNED_PACKAGES=n" > $(SOURCES_DIR)/sdk/.config
	make -C $(SOURCES_DIR)/sdk defconfig
	make -C $(SOURCES_DIR)/sdk package/sown-core/compile
	make -C $(SOURCES_DIR)/sdk package/sown-leds-ar150/compile
	make -C $(SOURCES_DIR)/sdk package/index

firmware: packages $(SOURCES_DIR)/imagebuilder 
	ln -fTs $(ROOT_DIR)/files $(SOURCES_DIR)/imagebuilder/files
	grep sown $(SOURCES_DIR)/imagebuilder/repositories.conf || echo "src sown file:/$(SOURCES_DIR)/sdk/bin/packages/mips_24kc/sown/" >> $(SOURCES_DIR)/imagebuilder/repositories.conf
	make -C $(SOURCES_DIR)/imagebuilder image PROFILE=gl-ar150 PACKAGES="sown-core sown-leds-ar150 -wpad-mini -dnsmasq -firewall" FILES=files/

.PHONY: all clean firmware packages 

all: firmware

clean:
	git clean -fdX
