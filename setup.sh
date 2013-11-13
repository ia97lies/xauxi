#!/bin/bash

. config/config.sh

COMPS="proxy content"
for i in $COMPS; do
  echo "package.path = package.path..\";$XAUXI_HOME/lib/?.lua;$LUALOGGER_HOME/src/?.lua;./?.lua\"" > server/$i/conf/xauxi.lua
  cat server/$i/conf/xauxi.template.lua >> server/$i/conf/xauxi.lua
done

