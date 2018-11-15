-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, sec, o, kcp_enable
local shadowsocks = "shadowsocks"
local uci = luci.model.uci.cursor()

local sys = require "luci.sys"

local gfwmode = 0

if nixio.fs.access("/etc/dnsmasq.shadowsocks/gfw_list.conf") then
	gfwmode = 1
end

m = Map(shadowsocks, translate("ShadowSocks Client"))

local server_table = {}
local arp_table = luci.ip.neighbors() or {}
local encrypt_methods = {
	"aes-128-cfb",
	"aes-192-cfb",
	"aes-256-cfb",
	"aes-128-ctr",
	"aes-192-ctr",
	"aes-256-ctr",
	"aes-128-gcm",
	"aes-192-gcm",
	"aes-256-gcm",
	"chacha20",
	"chacha20-ietf",
	"chacha20-ietf-poly1305"
}

uci:foreach(
	shadowsocks,
	"servers",
	function(s)
		if s.alias then
			server_table[s[".name"]] = s.alias
		elseif s.server and s.server_port then
			server_table[s[".name"]] = "%s:%s" % {s.server, s.server_port}
		end
	end
)

-- [[ Servers Setting ]]--
sec = m:section(TypedSection, "servers", translate("Servers Settings"))
sec.anonymous = true
sec.addremove = true
sec.sortable = true
sec.template = "cbi/tblsection"
sec.extedit = luci.dispatcher.build_url("admin/services/shadowsocks/client/%s")
function sec.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(sec.extedit % sid)
		return
	end
end

o = sec:option(DummyValue, "alias", translate("Alias"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = sec:option(DummyValue, "server", translate("Server Address"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "server_port", translate("Server Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "encrypt_method", translate("Encrypt Method"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "kcp_enable", translate("KcpTun"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "switch_enable", translate("Auto Switch"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

-- [[ Global Setting ]]--
s = m:section(TypedSection, "global", translate("Global Settings"))
s.anonymous = true

o = s:option(ListValue, "global_server", translate("Global Server"))
o:value("nil", translate("Disable"))
for k, v in pairs(server_table) do
	o:value(k, v)
end
o.default = "nil"
o.rmempty = false

if gfwmode == 1 then
	o = s:option(ListValue, "gfw_enable", translate("Use dnsmasq configurations"), translate("Enabling this will start a DNS tunnel with same configuration as global server and set localhost:5353 as dnsmasq upstream server"))
	o:value("disabled", translate("Disabled"))
	o:value("gfw", translate("from") .. " /etc/dnsmasq.shadowsocks")
	o.rmempty = false

	o = s:option(Value, "tunnel_forward", translate("Remote upstream DNS server IP and port"))
	o.default = "8.8.4.4:53"
	o.rmempty = false

	o = s:option(ListValue, "tunnel_port", translate("DNS tunnel listen port"), translate("You need to make sure there is a reliable DNS runing on localhost:5353"))
	o:value("5300", translate("5300 (use custom dns forwarder)"))
	o:value("5353", translate("5353 (serve directly as dnsmasq upstream)"))
	o.rmempty = false
end

o = s:option(ListValue, "udp_relay_server", translate("UDP Relay Server"))
o:value("", translate("Disable"))
o:value("same", translate("Same as Global Server"))
for k, v in pairs(server_table) do
	o:value(k, v)
end

o = s:option(Flag, "monitor_enable", translate("Enable Process Monitor"))
o.rmempty = false

o = s:option(Flag, "enable_switch", translate("Enable Auto Switch"))
o.rmempty = false

o = s:option(Value, "switch_time", translate("Switch check interval (seconds)"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 600

o = s:option(Value, "switch_timeout", translate("Check timeout (seconds)"))
o.datatype = "uinteger"
o:depends("enable_switch", "1")
o.default = 3

s = m:section(TypedSection, "socks5_proxy", translate("Socks5 Proxy"))
s.anonymous = true

o = s:option(ListValue, "server", translate("Server"))
o:value("nil", translate("Disable"))
for k, v in pairs(server_table) do
	o:value(k, v)
end
o.default = "nil"
o.rmempty = false

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.default = 1234
o.rmempty = false

-- [[ Access Control ]]--
s = m:section(TypedSection, "access_control", translate("Access Control"))
s.anonymous = true

-- Part of WAN
s:tab("wan_ac", translate("Interfaces - WAN"))

o = s:taboption("wan_ac", Value, "wan_bp_list", translate("Bypassed IP List"))
o:value("/dev/null", translate("NULL - As Global Proxy"))
o:value("/etc/chnroute.txt", translate("ChnRoute"))

o.default = "/dev/null"
o.rmempty = false

o = s:taboption("wan_ac", DynamicList, "wan_bp_ips", translate("Bypassed IP"))
o.datatype = "ip4addr"

o = s:taboption("wan_ac", DynamicList, "wan_fw_ips", translate("Forwarded IP"))
o.datatype = "ip4addr"

-- Part of LAN
s:tab("lan_ac", translate("Interfaces - LAN"))

o = s:taboption("lan_ac", ListValue, "router_proxy", translate("Router Proxy"))
o:value("1", translatef("Normal Proxy"))
o:value("0", translatef("Bypassed Proxy"))
o:value("2", translatef("Forwarded Proxy"))
o.rmempty = false

o = s:taboption("lan_ac", ListValue, "lan_ac_mode", translate("LAN Access Control"))
o:value("0", translate("Disable"))
o:value("w", translate("Allow listed only"))
o:value("b", translate("Allow all except listed"))
o.rmempty = false

o = s:taboption("lan_ac", DynamicList, "lan_ac_ips", translate("LAN Host List"))
o.datatype = "ipaddr"
for _, v in ipairs(arp_table) do
	o:value(v["IP address"])
end

return m
