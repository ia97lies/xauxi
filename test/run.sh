#!/bin/bash

CONCURRENT=$1
shift

TOP=..

. $TOP/config/config.sh

HTTEST_VERSION=`httest -V | grep "httest [0-9]\+\.[0-9]\+\.[0-9]\+" | awk '{ print $2 }'`
HTTEST_MAJOR=`echo $HTTEST_VERSION | awk -F. '{ print $1 }'`
HTTEST_MINOR=`echo $HTTEST_VERSION | awk -F. '{ print $2 }'`
HTTEST_MAINT=`echo $HTTEST_VERSION | awk -F. '{ print $3 }'`

export CONCURRENT

if [ $HTTEST_MAJOR -ge 2 -a $HTTEST_MINOR -ge 4 ]; then
  ARGS="-l"
else
  ARGS=""
fi

$HTTEST $ARGS $@
exit $?
