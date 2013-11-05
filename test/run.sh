#!/bin/bash

TOP=..

. $TOP/config/config.sh

$HTTEST -b -l $@
