-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

local m, sec, o
local shadowsocks = "shadowsocks"
local uci = luci.model.uci.cursor()

m = Map(shadowsocks, translate("ShadowSocks Server"))

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

-- [[ Global Setting ]]--
sec = m:section(TypedSection, "server_global", translate("Global Settings"))
sec.anonymous = true

o = sec:option(Flag, "enable_server", translate("Enable Server"))
o.rmempty = false

-- [[ Server Setting ]]--
sec = m:section(TypedSection, "server_config", translate("Server Settings"))
sec.anonymous = true
sec.addremove = true
sec.sortable = true
sec.template = "cbi/tblsection"
sec.extedit = luci.dispatcher.build_url("admin/services/shadowsocks/server/%s")
function sec.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(sec.extedit % sid)
		return
	end
end

o = sec:option(Flag, "enable", translate("Enable"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("0")
end
o.rmempty = false

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
	local v = Value.cfgvalue(...)
	return v and v:upper() or "?"
end

return m
