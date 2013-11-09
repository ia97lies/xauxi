#!/bin/bash

. config/config.sh

echo "package.path = package.path..\";$XAUXI_HOME/lib/?.lua;./?.lua\"" > server/simple/conf/xauxi.lua
cat server/simple/conf/xauxi.template.lua >> server/simple/conf/xauxi.lua

