#!/bin/bash
TOP=..

. $TOP/config/config.sh

error=0
for i in `ls integration/*.htt`; do
  unit=`echo $i | awk -F. '{ print $1 }'`
  printf "$unit... "
  >.tmp.out
  ./run.sh "" $unit.htt 2>> .tmp.out >> .tmp.out
  if [ $? -eq 0 ]; then
    echo ok
  else
    mv .tmp.out $unit.err
    echo failed
    set error=$error+1
  fi
done

if [ $error -ne 0 ]; then
  echo test failed
  exit -1
fi

