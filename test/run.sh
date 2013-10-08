#!/bin/bash

if [ -z $CONCURRENT ]; then
  export CONCURRENT=""
fi

HTTEST=httest
$HTTEST_PRE $HTTEST $@
