#!/bin/bash
if [ ! -d 3rdparty ]; then
  mkdir 3rdparty
fi

cd 3rdparty

wget http://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.gz/download -O boost_1_55_0.tar.gz
ln -s boost_1_55_0 boost
tar xzf boost_1_55_0.tar.gz
cd boost
./bootstrap.sh
./b2
cd ..

wget https://github.com/ignacio/LuaNode/archive/master.zip -O LuaNode.zip
ln -s LuaNode-master LuaNode
unzip -qq -o LuaNode.zip 
cd LuaNode/build
cmake ../ -DBOOST_ROOT=$HOME/workspace/xauxi/3rdparty/boost
make
cd ../..
rm LuaNode.zip

wget https://github.com/downloads/Neopallium/lualogging/lualogging-1.2.0.tbz 
ln -s lualogging-1.2.0 lualogging
tar xjf lualogging-1.2.0.tbz
rm lualogging-1.2.0.tbz
