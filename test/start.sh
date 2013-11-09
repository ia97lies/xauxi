#!/bin/bash
TOP=..

. $TOP/config/config.sh

$LUANODE $TOP/server/proxy/conf/xauxi.lua &
echo $! > .pid

