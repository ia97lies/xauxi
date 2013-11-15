#!/bin/bash
TOP=..

. $TOP/config/config.sh

> $XAUXI_HOME/server/proxy/logs/start.log
$LUANODE $XAUXI_HOME/server/proxy/conf/xauxi.lua >> $XAUXI_HOME/server/proxy/logs/start.log 2>> $XAUXI_HOME/server/proxy/logs/start.log &
echo $! > $XAUXI_HOME/server/proxy/run/.pid

> $XAUXI_HOME/server/content/logs/start.log
$LUANODE $XAUXI_HOME/server/content/conf/xauxi.lua >> $XAUXI_HOME/server/content/logs/start.log 2>> $XAUXI_HOME/server/content/logs/start.log &
echo $! > $XAUXI_HOME/server/content/run/.pid

