#!/bin/bash

. config/config.sh

> download.log
if [ ! -d "3rdparty" ]; then
  mkdir 3rdparty
fi

cd 3rdparty

print_status() {
  rc=$1
  if [ $rc -eq 0 ]; then
    printf " ok\n"
  else
    printf " failed\n"
  fi
}

check_pkg() {
  pkg=$1 
  if [ -f $pkg ]; then
    return 1
  else
    return 0
  fi
}

printf "   Download\n"

printf "       Lua"
check_pkg lua-5.2.2.tar.gz
if [ $? -eq 0 ]; then
  wget http://www.lua.org/ftp/lua-5.2.2.tar.gz -a download.log
  print_status $?
else
  printf " skip\n"
fi

printf "       OpenSSL"
check_pkg openssl-1.0.1e.tar.gz
if [ $? -eq 0 ]; then
  wget http://www.openssl.org/source/openssl-1.0.1e.tar.gz -a download.log
  print_status $?
else
  printf " skip\n"
fi

printf "       Boost"
check_pkg boost_1_55_0.tar.gz
if [ $? -eq 0 ]; then
  wget https://sourceforge.net/projects/boost/files/boost/1.55.0/boost_1_55_0.tar.gz -a download.log
  print_status $?
else
  printf " skip\n"
fi

printf "       Lualogging"
check_pkg lualogging-1.2.0.tbz
if [ $? -eq 0 ]; then
  wget https://github.com/downloads/Neopallium/lualogging/lualogging-1.2.0.tbz -a download.log
  print_status $?
else
  printf " skip\n"
fi

printf "       LuaNode"
check_pkg LuaNode.zip
if [ $? -eq 0 ]; then
  wget https://github.com/ignacio/LuaNode/archive/master.zip -O LuaNode.zip -a download.log
  print_status $?
else
  printf " skip\n"
fi


printf "    Extract\n"
printf "       Lua"
ln -s lua-5.2.2 lua
tar xzf lua-5.2.2.tar.gz
print_status $?

printf "       OpenSSL"
ln -s openssl-1.0.1e openssl
tar xzf openssl-1.0.1e.tar.gz
print_status $?

printf "       Boost"
ln -s boost_1_55_0 boost
tar xzf boost_1_55_0.tar.gz
print_status $?

printf "       Lualogging"
ln -s lualogging-1.2.0 lualogging
tar xjf lualogging-1.2.0.tbz
print_status $?

printf "       LuaNode"
ln -s LuaNode-master LuaNode
unzip -qq -o LuaNode.zip 
print_status $?



