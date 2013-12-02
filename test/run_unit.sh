#!/bin/bash
set -e

TOP=..

. $TOP/config/config.sh

for i in `ls unit/*.lua`; do
  unit=`echo $i | awk -F. '{ print $1 }'`
  echo
  echo "run test $unit.lua"
  $XAUXI run.lua $unit
done
