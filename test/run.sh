#!/bin/bash

TOP=..
export TOP

HTTEST=$TOP/../htt/src/httest
$HTTEST_PRE $HTTEST $@
