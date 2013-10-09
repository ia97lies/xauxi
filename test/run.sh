#!/bin/bash

if [ -z $TOP ]; then
  export TOP=..
fi

if [ -z $CONCURRENT ]; then
  export CONCURRENT=""
fi

HTTEST=httest
$HTTEST_PRE $HTTEST $@
