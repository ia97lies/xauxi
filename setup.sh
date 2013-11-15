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

  sed < server/$i/conf/xauxi.template.lua > server/$i/conf/xauxi.lua \
    -e "s;##XAUXI_HOME##;$XAUXI_HOME;g" \
    -e "s;##LUALOGGER_HOME##;$LUALOGGER_HOME;g"

  printf " ok\n"
done

