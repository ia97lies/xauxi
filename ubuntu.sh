#!/bin/bash
sudo apt-get install lua5.1 liblua5.1-0-dev lua-socket-dev liblua5.1-json httest libssl-dev  libboost-dev libboost-system-dev

if [ ! -d 3rdparty ]; then
  mkdir 3rdparty
fi
cd 3rdparty
wget https://github.com/ignacio/LuaNode/archive/master.zip -O LuaNode.zip
ln -s LuaNode-master LuaNode
unzip -qq -o LuaNode.zip 
cd LuaNode/build
cmake ../
make
cd ../..
rm LuaNode.zip

wget https://github.com/downloads/Neopallium/lualogging/lualogging-1.2.0.tbz 
ln -s lualogging-1.2.0 lualogging
tar xjf lualogging-1.2.0.tbz
rm lualogging-1.2.0.tbz
