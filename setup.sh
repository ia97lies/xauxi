#!/bin/bash

. config/config.sh

echo "package.path = package.path..\";$XAUXI_HOME/lib/?.lua;./?.lua\"" > server/proxy/conf/xauxi.lua
cat server/proxy/conf/xauxi.template.lua >> server/proxy/conf/xauxi.lua

