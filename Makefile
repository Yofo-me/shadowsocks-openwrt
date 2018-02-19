#
# Copyright (C) 2017 shadowsocks
# Copyright (C) 2017 yushi studio <ywb94@qq.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks
PKG_VERSION:=1.0.0
#PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/shadowsocks/shadowsocks-libev
PKG_SOURCE_VERSION:=6ea4455b84234c3dc57d1441eae2b13e214af476

PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=yushi studio <ywb94@qq.com>

#PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf
PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/shadowsocks/Default
	SECTION:=extra
	CATEGORY:=Extra Packages
	TITLE:=shadowsocks-libev LuCI interface
	URL:=https://github.com/ywb94/shadowsocks
	VARIANT:=$(1)
	DEPENDS:=$(3)	
	PKGARCH:=all
endef


Package/luci-app-shadowsocks = $(call Package/shadowsocks/Default,mbedtls,(mbedtls),+libmbedtls +libpthread +ipset +ip +iptables-mod-tproxy +libpcre +zlib +libsodium +libcares +libev +curl +ca-bundle)
Package/luci-app-shadowsocks-GFW = $(call Package/shadowsocks/Default,mbedtls,(mbedtls),+libmbedtls +libpthread +ipset +ip +iptables-mod-tproxy +libpcre +zlib +dnsmasq-full +libsodium +libcares +libev +curl +ca-bundle)

define Package/shadowsocks/description
	LuCI Support for $(1).
endef

Package/luci-app-shadowsocks/description = $(call Package/shadowsocks/description,shadowsocks-libev Client and Server)
Package/luci-app-shadowsocks-GFW/description = $(call Package/shadowsocks/description,shadowsocks-libev Client and Server with GFWList)

define Package/shadowsocks/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for shadowsocks"
    /etc/init.d/shadowsocks disable
    /etc/init.d/shadowsocks stop
    echo "Removing firewall rule for shadowsocks"
	uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocks
		commit firewall
EOF
	if [ "$(1)" = "GFW" ]; then
		sed -i '/conf-dir/d' /etc/dnsmasq.conf 
		/etc/init.d/dnsmasq restart 
	fi
fi
exit 0
endef

Package/luci-app-shadowsocks/prerm = $(call Package/shadowsocks/prerm,shadowsocks)
Package/luci-app-shadowsocks-GFW/prerm = $(call Package/shadowsocks/prerm,GFW)

define Package/luci-app-shadowsocks-Server/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/shadowsocks disable
	/etc/init.d/shadowsocks stop
fi 
exit 0
endef


define Package/shadowsocks/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocks
		set firewall.shadowsocks=include
		set firewall.shadowsocks.type=script
		set firewall.shadowsocks.path=/var/etc/shadowsocks.include
		set firewall.shadowsocks.reload=0
		commit firewall
EOF
fi

if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-shadowsocks ) && rm -f /etc/uci-defaults/luci-shadowsocks
	chmod 755 /etc/init.d/shadowsocks >/dev/null 2>&1
	/etc/init.d/shadowsocks enable >/dev/null 2>&1
fi
exit 0
endef

Package/luci-app-shadowsocks/postinst = $(call Package/shadowsocks/postinst,shadowsocks)
Package/luci-app-shadowsocks-GFW/postinst = $(call Package/shadowsocks/postinst,GFW)

define Package/luci-app-shadowsocks-Server/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-shadowsocks ) && rm -f /etc/uci-defaults/luci-shadowsocks
	chmod 755 /etc/init.d/shadowsocks >/dev/null 2>&1
	/etc/init.d/shadowsocks enable >/dev/null 2>&1
fi
exit 0
endef

CONFIGURE_ARGS += --disable-documentation --disable-ssp

define Package/shadowsocks/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/shadowsocks.lua $(1)/usr/lib/lua/luci/controller/shadowsocks.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/shadowsocks
	$(INSTALL_DATA) ./files/luci/model/cbi/shadowsocks/*.lua $(1)/usr/lib/lua/luci/model/cbi/shadowsocks/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/shadowsocks
	$(INSTALL_DATA) ./files/luci/view/shadowsocks/*.htm $(1)/usr/lib/lua/luci/view/shadowsocks/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/luci-shadowsocks $(1)/etc/uci-defaults/luci-shadowsocks
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-redir $(1)/usr/bin/ss-redir
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-tunnel $(1)/usr/bin/ss-tunnel
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-local $(1)/usr/bin/ss-local	
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-server $(1)/usr/bin/ss-server		
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-check $(1)/usr/bin/ss-check
	$(INSTALL_BIN) ./files/shadowsocks.rules $(1)/usr/bin/ss-rules
	$(INSTALL_BIN) ./files/shadowsocks.monitor $(1)/usr/bin/ss-monitor
	$(INSTALL_BIN) ./files/shadowsocks.switch $(1)/usr/bin/ss-switch
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocks.config $(1)/etc/config/shadowsocks
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/chnroute.txt $(1)/etc/chnroute.txt	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks.init $(1)/etc/init.d/shadowsocks
endef

define Package/luci-app-shadowsocks-GFW/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/shadowsocks.lua $(1)/usr/lib/lua/luci/controller/shadowsocks.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/shadowsocks
	$(INSTALL_DATA) ./files/luci/model/cbi/shadowsocks/*.lua $(1)/usr/lib/lua/luci/model/cbi/shadowsocks/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/shadowsocks
	$(INSTALL_DATA) ./files/luci/view/shadowsocks/*.htm $(1)/usr/lib/lua/luci/view/shadowsocks/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/luci-shadowsocks $(1)/etc/uci-defaults/luci-shadowsocks
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-redir $(1)/usr/bin/ss-redir
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-tunnel $(1)/usr/bin/ss-tunnel
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-local $(1)/usr/bin/ss-local	
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-server $(1)/usr/bin/ss-server		
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-check $(1)/usr/bin/ss-check
	$(INSTALL_BIN) ./files/shadowsocks.rules $(1)/usr/bin/ss-rules
	$(INSTALL_BIN) ./files/shadowsocks.monitor $(1)/usr/bin/ss-monitor
	$(INSTALL_BIN) ./files/shadowsocks.switch $(1)/usr/bin/ss-switch
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocks.config $(1)/etc/config/shadowsocks
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/chnroute.txt $(1)/etc/chnroute.txt	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks.init $(1)/etc/init.d/shadowsocks
	$(INSTALL_BIN) ./files/shadowsocks.gfw $(1)/usr/bin/ss-gfw
	$(INSTALL_DIR) $(1)/etc/dnsmasq.shadowsocks
	$(INSTALL_DATA) ./files/gfw_list.conf $(1)/etc/dnsmasq.shadowsocks/gfw_list.conf
endef

$(eval $(call BuildPackage,luci-app-shadowsocks))
$(eval $(call BuildPackage,luci-app-shadowsocks-GFW))
