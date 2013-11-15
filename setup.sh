#!/bin/bash

. config/config.sh

printf "   Setup\n"
COMPS="proxy content"
for i in $COMPS; do
  printf "     $i"
  if [ ! -d server/$i/run ]; then
    mkdir server/$i/run
  fi
  if [ ! -d server/$i/logs ]; then
    mkdir server/$i/logs
  fi

  echo "package.path = package.path..\";$XAUXI_HOME/lib/?.lua;$LUALOGGER_HOME/src/?.lua;./?.lua\"" > server/$i/conf/xauxi.lua
  cat server/$i/conf/xauxi.template.lua >> server/$i/conf/xauxi.lua
  printf " ok\n"
done

