#!/bin/bash

export TOP=..

if [ -z $srcdir ]; then
  srcdir=.
fi

. $srcdir/run_lib.sh

function run_single {
  E=$1
  OUT=$2

  ./run.sh $E >> $OUT 2>> $OUT
}

echo "start xauxi"
$TOP/src/xauxi --root $srcdir/simple --lib $TOP/lib > xauxi.log &
xauxi_pid=$!
sleep 2

LIST=`ls *.htt`
COUNT=`ls *.htt | wc -l`

echo "single tests"
run_all "$LIST" $COUNT

export CONCURRENT="30"
echo "concurrent tests ($CONCURRENT clients)"
run_all "$LIST" $COUNT

echo "stop xauxi"
kill $xauxi_pid
