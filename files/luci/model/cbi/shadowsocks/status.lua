-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local redir_run = 0
local reudp_run = 0
local sock5_run = 0
local server_run = 0
local tunnel_run = 0
local dns_whitelist_count = 0
local ad_count = 0
local ip_count = 0
local dnsmasq_conf = 0

if nixio.fs.access("/etc/dnsmasq.shadowsocks/accelerated-domains.china.conf") then
    dnsmasq_conf = 1
end

local shadowsocks = "shadowsocks"
-- html constants
font_blue = [[<font color="blue">]]
font_off = [[</font>]]
bold_on = [[<strong>]]
bold_off = [[</strong>]]

local fs = require "nixio.fs"
local sys = require "luci.sys"

if dnsmasq_conf == 1 then
    dns_whitelist_count = tonumber(sys.exec("cat /etc/dnsmasq.shadowsocks/accelerated-domains.china.conf | wc -l")) / 2
    if nixio.fs.access("/etc/dnsmasq.shadowsocks/ad.conf") then
        ad_count = tonumber(sys.exec("cat /etc/dnsmasq.shadowsocks/ad.conf | wc -l"))
    end
end

if nixio.fs.access("/etc/chnroute.txt") then
    ip_count = sys.exec("cat /etc/chnroute.txt | wc -l")
end

local icount = sys.exec("ps -w | grep ss-reudp | grep -v grep | wc -l")
if tonumber(icount) > 0 then
    reudp_run = 1
else
    icount = sys.exec('ps -w | grep ss-retcp | grep "\\-u"| grep -v grep | wc -l')
    if tonumber(icount) > 0 then
        reudp_run = 1
    end
end

if luci.sys.call("pidof ss-redir >/dev/null") == 0 then
    redir_run = 1
end

if luci.sys.call("pidof ss-local >/dev/null") == 0 then
    sock5_run = 1
end

if luci.sys.call("pidof ss-kcptun >/dev/null") == 0 then
    kcptun_run = 1
end

if luci.sys.call("pidof ss-server >/dev/null") == 0 then
    server_run = 1
end

if luci.sys.call("pidof ss-tunnel >/dev/null") == 0 then
    tunnel_run = 1
end

m = SimpleForm("Version", translate("Running Status"))
m.reset = false
m.submit = false

s = m:field(DummyValue, "redir_run", translate("ShadowSocks Redir Client"))
s.rawhtml = true
if redir_run == 1 then
    s.value = font_blue .. bold_on .. translate("Running") .. bold_off .. font_off
else
    s.value = translate("Not Running")
end

s = m:field(DummyValue, "reudp_run", translate("ShadowSocks UDP Relay"))
s.rawhtml = true
if reudp_run == 1 then
    s.value = font_blue .. bold_on .. translate("Running") .. bold_off .. font_off
else
    s.value = translate("Not Running")
end

s = m:field(DummyValue, "sock5_run", translate("ShadowSocks SOCKS5 Proxy"))
s.rawhtml = true
if sock5_run == 1 then
    s.value = font_blue .. bold_on .. translate("Running") .. bold_off .. font_off
else
    s.value = translate("Not Running")
end

s = m:field(DummyValue, "tunnel_run", translate("ShadowSocks DNS Tunnel"))
s.rawhtml = true
if tunnel_run == 1 then
    s.value = font_blue .. bold_on .. translate("Running") .. bold_off .. font_off
else
    s.value = translate("Not Running")
end

s = m:field(DummyValue, "server_run", translate("ShadowSocks Server"))
s.rawhtml = true
if server_run == 1 then
    s.value = font_blue .. bold_on .. translate("Running") .. bold_off .. font_off
else
    s.value = translate("Not Running")
end

s = m:field(DummyValue, "google", translate("Google Connectivity"))
s.value = translate("No Check")
s.template = "shadowsocks/check"

s = m:field(DummyValue, "baidu", translate("Baidu Connectivity"))
s.value = translate("No Check")
s.template = "shadowsocks/check"

if dnsmasq_conf == 1 then
    s = m:field(DummyValue, "dns_whitelist_data", translate("DNS White List Data"))
    s.rawhtml = true
    s.template = "shadowsocks/refresh"
    s.value = tostring(math.ceil(dns_whitelist_count)) .. " " .. translate("Records")

    s = m:field(DummyValue, "ad_data", translate("Advertising Data"))
    s.rawhtml = true
    s.template = "shadowsocks/refresh"
    s.value = tostring(math.ceil(ad_count)) .. " " .. translate("Records")
end

s = m:field(DummyValue, "ip_data", translate("China IP Data"))
s.rawhtml = true
s.template = "shadowsocks/refresh"
s.value = ip_count .. " " .. translate("Records")

s = m:field(DummyValue, "check_port", translate("Check Server Port"))
s.template = "shadowsocks/checkport"
s.value = translate("No Check")

return m
