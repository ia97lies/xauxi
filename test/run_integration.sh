#!/bin/bash
TOP=..

. $TOP/config/config.sh

for i in `ls integration/*.htt`; do
  unit=`echo $i | awk -F. '{ print $1 }'`
  ./run.sh "" $unit.htt
done
