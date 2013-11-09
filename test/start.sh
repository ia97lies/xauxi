#!/bin/bash
TOP=..

. $TOP/config/config.sh

$LUANODE $TOP/server/simple/conf/xauxi.lua &
echo $! > .pid

