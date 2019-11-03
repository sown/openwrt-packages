ROOT_DIR = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
download_sdk:
	mkdir -p build
	wget https://downloads.openwrt.org/releases/18.06.4/targets/ar71xx/generic/openwrt-sdk-18.06.4-ar71xx-generic_gcc-7.3.0_musl.Linux-x86_64.tar.xz -O build/sdk.tar.xz
	mkdir build/sdk
	tar -xvf build/sdk.tar.xz -C build/sdk --strip 1

download_imagebuilder:
	mkdir -p build
	wget https://downloads.openwrt.org/releases/18.06.4/targets/ar71xx/generic/openwrt-imagebuilder-18.06.4-ar71xx-generic.Linux-x86_64.tar.xz -O build/imagebuilder.tar.xz
	mkdir -p build/imagebuilder
	tar -xvf build/imagebuilder.tar.xz -C build/imagebuilder --strip 1

packages:
	grep sown build/sdk/feeds.conf.default || echo "src-link sown $(ROOT_DIR)" >> build/sdk/feeds.conf.default
	build/sdk/scripts/feeds update sown
	build/sdk/scripts/feeds install sown-core
	build/sdk/scripts/feeds install sown-leds-ar150
	echo "CONFIG_SIGNED_PACKAGES=n" > build/sdk/.config
	cd build/sdk && make defconfig
	cd build/sdk && make package/sown-core/compile
	cd build/sdk && make package/sown-leds-ar150/compile
	cd build/sdk && make package/index

firmware:
	ln -fTs $(ROOT_DIR)/files build/imagebuilder/files
	grep sown build/imagebuilder/repositories.conf || echo "src sown file:/$(ROOT_DIR)/build/sdk/bin/packages/mips_24kc/sown/" >> build/imagebuilder/repositories.conf
	cd build/imagebuilder && make image PROFILE=gl-ar150 PACKAGES="sown-core sown-leds-ar150 -wpad-mini -dnsmasq" FILES=files/

all: download_sdk download_imagebuilder packages firmware
