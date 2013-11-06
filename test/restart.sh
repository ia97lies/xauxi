#!/bin/bash
TOP=..

. $TOP/config/config.sh


kill `cat .pid`
$LUA_NODE $TOP/lib/proxy.lua &
echo $! > .pid

