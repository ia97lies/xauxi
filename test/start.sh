#!/bin/bash
TOP=..

. $TOP/config/config.sh

$LUA_NODE $TOP/lib/proxy.lua &
echo $! > .pid

