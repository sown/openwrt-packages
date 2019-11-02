ROOT_DIR = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
download_sdk:
	mkdir -p build/sdk
	wget https://downloads.openwrt.org/releases/18.06.4/targets/ar71xx/generic/openwrt-sdk-18.06.4-ar71xx-generic_gcc-7.3.0_musl.Linux-x86_64.tar.xz -O build/sdk.tar.xz
	tar -xvf build/sdk.tar.xz -C build/sdk --strip 1

download_imagebuilder:
	mkdir -p build/imagebuilder
	wget https://downloads.openwrt.org/releases/18.06.4/targets/ar71xx/generic/openwrt-imagebuilder-18.06.4-ar71xx-generic.Linux-x86_64.tar.xz -O build/imagebuilder.tar.xz
	tar -xvf build/imagebuilder.tar.xz -C build/imagebuilder --strip 1

packages: download_sdk 
	grep sown build/sdk/feeds.conf.default || echo "src-link sown $(ROOT_DIR)" >> build/sdk/feeds.conf.default
	build/sdk/scripts/feeds update sown
	build/sdk/scripts/feeds install sown-core
	build/sdk/scripts/feeds install sown-leds-ar150
	echo "CONFIG_SIGNED_PACKAGES=n" > build/sdk/.config
	make -C build/sdk defconfig
	make -C build/sdk package/sown-core/compile
	make -C build/sdk package/sown-leds-ar150/compile
	make -C build/sdk package/index

firmware: packages download_imagebuilder
	ln -s $(ROOT_DIR)/files build/imagebuilder/files
	grep sown build/imagebuilder/repositories.conf || echo "src sown file:/$(ROOT_DIR)/build/sdk/bin/packages/mips_24kc/sown/" >> build/imagebuilder/repositories.conf
	make -C build/imagebuilder image PROFILE=gl-ar150 PACKAGES="sown-core sown-leds-ar150 -wpad-mini -dnsmasq" FILES=files/

.PHONY: all clean firmware packages download_sdk download_imagebuilder

all: firmware

clean:
	git clean -fdX
