#!/bin/bash
TOP=..

. $TOP/config/config.sh

$LUANODE $XAUXI_HOME/server/proxy/conf/xauxi.lua 2>&1 >/dev/null &
echo $! > $XAUXI_HOME/server/proxy/run/.pid

$LUANODE $XAUXI_HOME/server/content/conf/xauxi.lua 2>&1 >/dev/null &
echo $! > $XAUXI_HOME/server/content/run/.pid

