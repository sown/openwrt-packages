
ROOT_DIR = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR = "$(ROOT_DIR)/build"

SDK_DIR = "$(BUILD_DIR)/sdk"
IMAGEBUILDER_DIR = "$(BUILD_DIR)/imagebuilder"

build/sdk.tar.xz:
	mkdir -p $(BUILD_DIR)
	wget https://downloads.openwrt.org/releases/18.06.4/targets/ar71xx/generic/openwrt-sdk-18.06.4-ar71xx-generic_gcc-7.3.0_musl.Linux-x86_64.tar.xz -O build/sdk.tar.xz

build/imagebuilder.tar.xz:
	mkdir -p $(BUILD_DIR)
	wget https://downloads.openwrt.org/releases/18.06.4/targets/ar71xx/generic/openwrt-imagebuilder-18.06.4-ar71xx-generic.Linux-x86_64.tar.xz -O build/imagebuilder.tar.xz

extract_sdk: build/sdk.tar.xz
	mkdir -p $(SDK_DIR)
	tar -xf $(BUILD_DIR)/sdk.tar.xz -C $(SDK_DIR) --strip 1

extract_imagebuilder: build/imagebuilder.tar.xz
	mkdir -p $(IMAGEBUILDER_DIR)
	tar -xf build/imagebuilder.tar.xz -C $(IMAGEBUILDER_DIR) --strip 1

packages: extract_sdk 
	grep sown $(SDK_DIR)/feeds.conf.default || echo "src-link sown $(ROOT_DIR)" >> $(SDK_DIR)/feeds.conf.default
	$(SDK_DIR)/scripts/feeds update sown
	$(SDK_DIR)/scripts/feeds install sown-core
	$(SDK_DIR)/scripts/feeds install sown-leds-ar150
	echo "CONFIG_SIGNED_PACKAGES=n" > $(SDK_DIR)/.config
	make -C $(SDK_DIR) defconfig
	make -C $(SDK_DIR) package/sown-core/compile
	make -C $(SDK_DIR) package/sown-leds-ar150/compile
	make -C $(SDK_DIR) package/index

firmware: packages extract_imagebuilder
	ln -fTs $(ROOT_DIR)/files $(IMAGEBUILDER_DIR)/files
	grep sown $(IMAGEBUILDER_DIR)/repositories.conf || echo "src sown file:/$(SDK_DIR)/bin/packages/mips_24kc/sown/" >> $(IMAGEBUILDER_DIR)/repositories.conf
	make -C $(IMAGEBUILDER_DIR) image PROFILE=gl-ar150 PACKAGES="sown-core sown-leds-ar150 -wpad-mini -dnsmasq -firewall" FILES=files/

.PHONY: all clean firmware packages extract_sdk extract_imagebuilder

all: firmware

clean:
	git clean -fdX
