#!/bin/bash
TOP=..

. $TOP/config/config.sh

$LUA_NODE $TOP/server/simple/conf/xauxi.lua &
echo $! > .pid

