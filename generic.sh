#!/bin/bash

set -e

. config/config.sh

if [ ! -d 3rdparty ]; then
  mkdir 3rdparty
fi

cd 3rdparty

###############################################################################
## boost library
###############################################################################
boost_version_tar=`echo $BOOST_VERSION | awk -F. '{ printf "%s_%s_%s", $1, $2, $3 }'`
boost_version_dir=$BOOST_VERSION
if [ ! -d boost_${boost_version_tar} ]; then
  if [ ! -f boost_${boost_version_tar}.tar.gz ]; then
    wget http://sourceforge.net/projects/boost/files/boost/${boost_version_dir}/boost_${boost_version_tar}.tar.gz/download -O boost_${boost_version_tar}.tar.gz
  fi
  rm -f boost
  tar xzf boost_${boost_version_tar}.tar.gz
  ln -s boost_${boost_version_tar} boost
fi

cd boost
./bootstrap.sh
./b2 --with-system --with-chrono --with-date_time --with-thread
cd ..

###############################################################################
## LuaNode
###############################################################################
if [ ! -d LuaNode-master ]; then
  if [ ! -f LuaNode.zip ]; then
    wget https://github.com/ignacio/LuaNode/archive/master.zip -O LuaNode.zip
  fi
  rm -f LuaNode
  unzip -qq -o LuaNode.zip 
  ln -s LuaNode-master LuaNode
fi
cd LuaNode/build
cmake ../ -DBOOST_ROOT=$HOME/workspace/xauxi/3rdparty/boost
make
cd ../..

###############################################################################
## lualogging
###############################################################################
if [ ! -d lualogging-$LUALOGGING_VERSION ]; then
  if [ ! -f lualogging-$LUALOGGING_VERSION.tbz ]; then
    wget https://github.com/downloads/Neopallium/lualogging/lualogging-$LUALOGGING_VERSION.tbz 
  fi
  rm -f lualogging
  tar xjf lualogging-$LUALOGGING_VERSION.tbz
  ln -s lualogging-$LUALOGGING_VERSION lualogging
fi

