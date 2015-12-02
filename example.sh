#!/bin/ash
cd $(dirname $0)
/usr/bin/lua cclogin.lua logout
/usr/bin/lua cclogin.lua login