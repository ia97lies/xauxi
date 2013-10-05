#!/bin/bash

TOP=..
export TOP

if [ -z $CONCURRENT ]; then
  export CONCURRENT=""
fi

HTTEST=$TOP/../htt/src/httest
$HTTEST_PRE $HTTEST $@
