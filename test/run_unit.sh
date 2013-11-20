#!/bin/bash
TOP=..

. $TOP/config/config.sh

for i in `ls unit/*.lua`; do
  unit=`echo $i | awk -F. '{ print $1 }'`
  $LUANODE run.lua $unit
done
