#
# Copyright (C) 2015 SOWN
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=sown-leds-mifi
PKG_VERSION:=0.3
PKG_RELEASE:=2015

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/sown-leds-mifi
  SECTION:=sown
  CATEGORY:=SOWN
  SUBMENU:=
  DEPENDS:=-sown-leds-ar150
  TITLE:=Southampton Open Wireless Network - LEDs - GL.iNet MiFi
  VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	$(CP) -a files $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/sown-leds-mifi/install
	$(INSTALL_DIR) $(1)/etc/rc.local.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rc.local.d_leds $(1)/etc/rc.local.d/leds
	$(INSTALL_DIR) $(1)/etc/rc.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rc.d_early_leds $(1)/etc/rc.d/S00_early_leds
	$(INSTALL_DIR) $(1)/etc/sown/events/tunnel_up.d
	$(INSTALL_DIR) $(1)/etc/sown/events/tunnel_up_delayed.d
	$(INSTALL_DIR) $(1)/etc/sown/events/tunnel_down.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/tunnel_down.d_leds $(1)/etc/sown/events/tunnel_down.d/leds
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/tunnel_up.d_leds $(1)/etc/sown/events/tunnel_up.d/leds
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/tunnel_up_delayed.d_leds $(1)/etc/sown/events/tunnel_up_delayed.d/leds
endef

$(eval $(call BuildPackage,sown-leds-mifi))
