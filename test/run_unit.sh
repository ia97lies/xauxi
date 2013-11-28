#!/bin/bash
set -e

TOP=..

. $TOP/config/config.sh

for i in `ls unit/*.lua`; do
  unit=`echo $i | awk -F. '{ print $1 }'`
  $XAUXI run.lua $unit
done
