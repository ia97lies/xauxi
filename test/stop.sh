#!/bin/bash
TOP=..

. $TOP/config/config.sh

kill `cat $XAUXI_HOME/server/proxy/run/.pid`
rm $XAUXI_HOME/server/proxy/run/.pid

kill `cat $XAUXI_HOME/server/content/run/.pid`
rm $XAUXI_HOME/server/content/run/.pid

