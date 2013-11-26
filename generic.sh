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
if [ ! -f boost_${boost_version_tar}.tar.gz ]; then
	wget http://sourceforge.net/projects/boost/files/boost/${boost_version_dir}/boost_${boost_version_tar}.tar.gz/download -O boost-${boost_version_dir}.tar.gz
	ln -s boost-${boost_version_dir} boost
	tar xzf boost-${boost_version_dir}.tar.gz
fi
cd boost
./bootstrap.sh
./b2
cd ..
rm -rf boost-*.tar.gz 

###############################################################################
## LuaNode
###############################################################################
if [ ! -f LuaNode.zip ]; then
	wget https://github.com/ignacio/LuaNode/archive/master.zip -O LuaNode.zip
	ln -s LuaNode-master LuaNode
	unzip -qq -o LuaNode.zip 
fi
cd LuaNode/build
cmake ../ -DBOOST_ROOT=$HOME/workspace/xauxi/3rdparty/boost
make
cd ../..
rm -rf LuaNode.zip

###############################################################################
## lualogging
###############################################################################
if [ ! -f lualogging-$LUALOGGING_VERSION ]; then
	wget https://github.com/downloads/Neopallium/lualogging/lualogging-$LUALOGGING_VERSION.tbz 
	ln -s lualogging-$LUALOGGING_VERSION lualogging
	tar xjf lualogging-$LUALOGGING_VERSION.tbz
fi
rm -rf lualogging-$LUALOGGING_VERSION.tbz

