#!/bin/bash

echo $bindir

if [ -z $srcdir ]; then
  srcdir=.
fi

export TOP=$srcdir/..

. $srcdir/run_lib.sh

function run_single {
  E=$1
  OUT=$2

  $srcdir/run.sh $E >> $OUT 2>> $OUT
}

httest -V >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  echo "httest is not in your PATH"
  exit 1
fi

LIST=`ls $srcdir/*.htt`
COUNT=`ls $srcdir/*.htt | wc -l`

echo "single tests"
run_all "$LIST" $COUNT

export CONCURRENT="30"
echo "concurrent tests ($CONCURRENT clients)"
run_all "$LIST" $COUNT

echo "stop xauxi"
if [ -f .pid ]; then
  kill `cat .pid` 
  rm -f .type
fi

if [ $errors -ne 0 ]; then
  exit 1
fi

