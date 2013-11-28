#!/bin/bash

. config/config.sh

printf "   Setup\n"
printf "     Lua path"
echo "package.path = package.path..\";${XAUXI_HOME}/build/?.lua;\"" > test/config.lua
echo "XAUXI_HOME = \"${XAUXI_HOME}\"" >> test/config.lua
printf " ok\n"
mkdir -p server/proxy/logs
mkdir -p server/proxy/run
mkdir -p server/content/logs
mkdir -p server/content/run
mkdir -p build/bin
cp -r ${LUANODE_HOME}/build/luanode build/bin/xauxi
cp -r lib/* build/.
cp -r ${LUALOGGING_HOME}/src/* build/.
cp -r ${LUANODE_HOME}/lib/luanode build/.

