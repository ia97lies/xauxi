#!/bin/bash

echo aclocal
aclocal
echo autoconf
autoconf
echo automake --add-missing
automake --add-missing
echo autoreconf -f -i
autoreconf
echo autoheader
autoheader
echo automake -i -f -a
automake -i -f -a
echo libtoolize
if [ `uname -s` == "Darwin" ]; then
  glibtoolize
else
  libtoolize
fi
