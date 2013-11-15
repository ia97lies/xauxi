#!/bin/bash
TOP=..

. $TOP/config/config.sh

$LUANODE $XAUXI_HOME/server/proxy/conf/xauxi.lua >> server.log 2>> server.log &
echo $! > $XAUXI_HOME/server/proxy/run/.pid

$LUANODE $XAUXI_HOME/server/content/conf/xauxi.lua >> server.log 2>> server.log &
echo $! > $XAUXI_HOME/server/content/run/.pid

