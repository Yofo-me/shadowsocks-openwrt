-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, o, kcp_enable
local shadowsocks = "shadowsocks"
local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local sid = arg[1]
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

m = Map(shadowsocks, translate("Edit ShadowSocks Server"))
m.redirect = luci.dispatcher.build_url("admin/services/shadowsocks/client")
if m.uci:get(shadowsocks, sid) ~= "servers" then
	luci.http.redirect(m.redirect)
	return
end

-- [[ Servers Setting ]]--
s = m:section(NamedSection, sid, "servers")
s.anonymous = true
s.addremove = false

o = s:option(Value, "alias", translate("Alias(optional)"))

o = s:option(Flag, "switch_enable", translate("Auto Switch"))
o.rmempty = false

o = s:option(Value, "server", translate("Server Address"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", translate("Server Port"))
o.datatype = "port"
o.rmempty = false

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.default = 1234
o.rmempty = false

o = s:option(Value, "timeout", translate("Connection Timeout"))
o.datatype = "uinteger"
o.default = 60
o.rmempty = false

o = s:option(Value, "password", translate("Password"))
o.password = true
o.rmempty = false

o = s:option(ListValue, "encrypt_method", translate("Encrypt Method"))
for _, v in ipairs(encrypt_methods) do
	o:value(v)
end
o.rmempty = false

o = s:option(Flag, "fast_open", translate("TCP Fast Open"))
o.rmempty = false

return m
