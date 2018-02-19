#
# Copyright (C) 2017 shadowsocks-openwrt
# Copyright (C) 2017 yushi studio <ywb94@qq.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocks-openwrt
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

define Package/shadowsocks-openwrt/Default
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=shadowsocks-openwrt-libev LuCI interface
	URL:=https://github.com/ywb94/shadowsocks-openwrt
	VARIANT:=$(1)
	DEPENDS:=$(3)	
	PKGARCH:=all
endef


Package/luci-app-shadowsocks-openwrt = $(call Package/shadowsocks-openwrt/Default,mbedtls,(mbedtls),+libmbedtls +libpthread +ipset +ip +iptables-mod-tproxy +libpcre +zlib +libsodium +libcares +libev)
Package/luci-app-shadowsocks-openwrt-Client = $(call Package/shadowsocks-openwrt/Default,mbedtls,(mbedtls),+libmbedtls +libpthread +ipset +ip +iptables-mod-tproxy +libpcre +zlib +libsodium +libcares +libev)
Package/luci-app-shadowsocks-openwrt-Server = $(call Package/shadowsocks-openwrt/Default,mbedtls,(mbedtls),+libmbedtls +libpthread +ipset +ip +iptables-mod-tproxy +libpcre +zlib +libsodium +libcares +libev)
Package/luci-app-shadowsocks-openwrt-GFW = $(call Package/shadowsocks-openwrt/Default,mbedtls,(mbedtls),+libmbedtls +libpthread +ipset +ip +iptables-mod-tproxy +libpcre +zlib +dnsmasq-full +libsodium +libcares +libev)

define Package/shadowsocks-openwrt/description
	LuCI Support for $(1).
endef

Package/luci-app-shadowsocks-openwrt/description = $(call Package/shadowsocks-openwrt/description,shadowsocks-openwrt-libev Client and Server)
Package/luci-app-shadowsocks-openwrt-Client/description = $(call Package/shadowsocks-openwrt/description,shadowsocks-openwrt-libev Client)
Package/luci-app-shadowsocks-openwrt-Server/description = $(call Package/shadowsocks-openwrt/description,shadowsocks-openwrt-libev Server)
Package/luci-app-shadowsocks-openwrt-GFW/description = $(call Package/shadowsocks-openwrt/description,shadowsocks-openwrt-libev GFW)

define Package/shadowsocks-openwrt/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for shadowsocks-openwrt"
    /etc/init.d/shadowsocks-openwrt disable
    /etc/init.d/shadowsocks-openwrt stop
    echo "Removing firewall rule for shadowsocks-openwrt"
	uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocks-openwrt
		commit firewall
EOF
	if [ "$(1)" = "GFW" ]; then
		sed -i '/conf-dir/d' /etc/dnsmasq.conf 
		/etc/init.d/dnsmasq restart 
	fi
fi
exit 0
endef

Package/luci-app-shadowsocks-openwrt/prerm = $(call Package/shadowsocks-openwrt/prerm,shadowsocks-openwrt)
Package/luci-app-shadowsocks-openwrt-Client/prerm = $(call Package/shadowsocks-openwrt/prerm,shadowsocks-openwrt)
Package/luci-app-shadowsocks-openwrt-GFW/prerm = $(call Package/shadowsocks-openwrt/prerm,GFW)

define Package/luci-app-shadowsocks-openwrt-Server/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/shadowsocks-openwrt disable
	/etc/init.d/shadowsocks-openwrt stop
fi 
exit 0
endef


define Package/shadowsocks-openwrt/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocks-openwrt
		set firewall.shadowsocks-openwrt=include
		set firewall.shadowsocks-openwrt.type=script
		set firewall.shadowsocks-openwrt.path=/var/etc/shadowsocks-openwrt.include
		set firewall.shadowsocks-openwrt.reload=0
		commit firewall
EOF
fi

if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-shadowsocks-openwrt ) && rm -f /etc/uci-defaults/luci-shadowsocks-openwrt
	chmod 755 /etc/init.d/shadowsocks-openwrt >/dev/null 2>&1
	/etc/init.d/shadowsocks-openwrt enable >/dev/null 2>&1
fi
exit 0
endef

Package/luci-app-shadowsocks-openwrt/postinst = $(call Package/shadowsocks-openwrt/postinst,shadowsocks-openwrt)
Package/luci-app-shadowsocks-openwrt-Client/postinst = $(call Package/shadowsocks-openwrt/postinst,shadowsocks-openwrt)
Package/luci-app-shadowsocks-openwrt-GFW/postinst = $(call Package/shadowsocks-openwrt/postinst,GFW)

define Package/luci-app-shadowsocks-openwrt-Server/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-shadowsocks-openwrt ) && rm -f /etc/uci-defaults/luci-shadowsocks-openwrt
	chmod 755 /etc/init.d/shadowsocks-openwrt >/dev/null 2>&1
	/etc/init.d/shadowsocks-openwrt enable >/dev/null 2>&1
fi
exit 0
endef

CONFIGURE_ARGS += --disable-documentation --disable-ssp

define Package/shadowsocks-openwrt/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/$(2).lua $(1)/usr/lib/lua/luci/controller/$(2).lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/shadowsocks
	$(INSTALL_DATA) ./files/luci/model/cbi/shadowsocks/*.lua $(1)/usr/lib/lua/luci/model/cbi/shadowsocks/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/shadowsocks-openwrt
	$(INSTALL_DATA) ./files/luci/view/shadowsocks/*.htm $(1)/usr/lib/lua/luci/view/shadowsocks/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/luci-$(2) $(1)/etc/uci-defaults/luci-$(2)
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-redir $(1)/usr/bin/ss-redir
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-tunnel $(1)/usr/bin/ss-tunnel
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-local $(1)/usr/bin/ss-local	
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-server $(1)/usr/bin/ss-server		
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-check $(1)/usr/bin/ss-check
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.rules $(1)/usr/bin/ss-rules
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.monitor $(1)/usr/bin/ss-monitor
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.switch $(1)/usr/bin/ss-switch
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocks-openwrt.config $(1)/etc/config/shadowsocks-openwrt
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/chnroute.txt $(1)/etc/chnroute.txt	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.init $(1)/etc/init.d/shadowsocks-openwrt
endef

Package/luci-app-shadowsocks-openwrt/install = $(call Package/shadowsocks-openwrt/install,$(1),shadowsocks-openwrt)

define Package/luci-app-shadowsocks-openwrt-Client/install
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
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-check $(1)/usr/bin/ss-check
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.rules $(1)/usr/bin/ss-rules
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.monitor $(1)/usr/bin/ss-monitor
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.switch $(1)/usr/bin/ss-switch
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocks-openwrt.config $(1)/etc/config/shadowsocks-openwrt
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/china_ssr.txt $(1)/etc/china_ssr.txt	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.init $(1)/etc/init.d/shadowsocks-openwrt
endef

define Package/luci-app-shadowsocks-openwrt-Server/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/shadowsocks.lua $(1)/usr/lib/lua/luci/controller/shadowsocks.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/shadowsocks
	$(INSTALL_DATA) ./files/luci/model/cbi/shadowsocks/*.lua $(1)/usr/lib/lua/luci/model/cbi/shadowsocks/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/shadowsocks
	$(INSTALL_DATA) ./files/luci/view/shadowsocks/*.htm $(1)/usr/lib/lua/luci/view/shadowsocks/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/luci-shadowsocks $(1)/etc/uci-defaults/luci-shadowsocks
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-server $(1)/usr/bin/ss-server		
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.rules $(1)/usr/bin/ss-rules
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.monitor $(1)/usr/bin/ss-monitor
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocks-openwrt.config $(1)/etc/config/shadowsocks-openwrt
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.init $(1)/etc/init.d/shadowsocks-openwrt
endef

define Package/luci-app-shadowsocks-openwrt-GFW/install
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
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.rules $(1)/usr/bin/ss-rules
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.monitor $(1)/usr/bin/ss-monitor
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.gfw $(1)/usr/bin/ss-gfw
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.switch $(1)/usr/bin/ss-switch
	$(INSTALL_DIR) $(1)/etc/dnsmasq.ssr
	$(INSTALL_DATA) ./files/gfw_list.conf $(1)/etc/dnsmasq.ssr/gfw_list.conf
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocks-openwrt.config $(1)/etc/config/shadowsocks-openwrt
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/chnroute.txt $(1)/etc/chnroute.txt	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks-openwrt.init $(1)/etc/init.d/shadowsocks-openwrt
endef

$(eval $(call BuildPackage,luci-app-shadowsocks-openwrt))
#$(eval $(call BuildPackage,luci-app-shadowsocks-openwrt-Client))
#$(eval $(call BuildPackage,luci-app-shadowsocks-openwrt-Server))
$(eval $(call BuildPackage,luci-app-shadowsocks-openwrt-GFW))
