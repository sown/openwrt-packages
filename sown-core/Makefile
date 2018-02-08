#
# Copyright (C) 2015 SOWN
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=sown-core
PKG_VERSION:=0.7
PKG_RELEASE:=2016

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/sown-core
  SECTION:=sown
  CATEGORY:=SOWN
  SUBMENU:=
  DEPENDS:=+dnsmasq +curl +kmod-ipt-ipopt +kmod-ipt-conntrack +kmod-ipt-extra +kmod-ipt-nat +kmod-ip6tables +ip6tables +hostapd
  TITLE:=Southampton Open Wireless Network - Core Package
  VERSION:=$(PKG_VERSION)-$(PKG_RELEASE)
endef

define Package/sown-core/conffiles
/etc/config/sown_core
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	$(CP) -a files $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/sown-core/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/config/* $(1)/etc/config/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/uci-defaults/* $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/etc/sown
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/ca.crt $(1)/etc/sown/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/constants.sh $(1)/etc/sown/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/functions.sh $(1)/etc/sown/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/node_control_2015.crt $(1)/etc/sown/
	$(INSTALL_DIR) $(1)/etc/sown/configure_scripts/available/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/configure_scripts/available/* $(1)/etc/sown/configure_scripts/available/
	$(INSTALL_DIR) $(1)/etc/sown/configure_scripts/enabled/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/configure_scripts/enabled/* $(1)/etc/sown/configure_scripts/enabled/
	$(INSTALL_DIR) $(1)/etc/sown/crontabs/at-boot/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/crontabs/at_boot/* $(1)/etc/sown/crontabs/at-boot/
	$(INSTALL_DIR) $(1)/etc/sown/crontabs/available/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/crontabs/available/* $(1)/etc/sown/crontabs/available/
	$(INSTALL_DIR) $(1)/etc/sown/events/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/events/tunnel_up $(1)/etc/sown/events/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/events/tunnel_down $(1)/etc/sown/events/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/events/tunnel_up_delayed $(1)/etc/sown/events/
	$(INSTALL_DIR) $(1)/etc/sown/events/tunnel-up.d
	$(INSTALL_DIR) $(1)/etc/sown/events/tunnel-down.d
	$(INSTALL_DIR) $(1)/etc/sown/firewall/chains/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/sown/firewall/chains/* $(1)/etc/sown/firewall/chains/
	$(INSTALL_DIR) $(1)/etc/ssl/certs
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/ssl/certs/* $(1)/etc/ssl/certs/
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/bin/* $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/sbin/* $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,sown-core))
