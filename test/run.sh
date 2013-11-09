#!/bin/bash

CONCURRENT=$1
shift

TOP=..

. $TOP/config/config.sh

export CONCURRENT
$HTTEST -b -l $@
