#!/bin/bash

. config/config.sh

printf "   Setup\n"
printf "     Lua path"
echo "package.path = package.path..\";${XAUXI_HOME}/lib/?.lua;${LUALOGGER_HOME}/src/?.lua;./?.lua\"" > test/config.lua
echo "XAUXI_HOME = \"${XAUXI_HOME}\"" >> test/config.lua
printf " ok\n"
