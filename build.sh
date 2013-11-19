#!/bin/bash

cd 3rdparty

print_status() {
  rc=$1
  if [ $rc -eq 0 ]; then
    printf " ok\n"
  else
    printf " failed\n"
  fi
}

>build.log
printf "Build xauxi\n"
printf "  Build\n"
printf "    openssl"
cd openssl
./config >> build.log 2>> build.log
make >> build.log 2>> build.log
print_status $?
cd ..
printf "    boost"
cd boost
./bootstrap.sh >> build.log 2>> build.log
./b2 >> build.log 2>> build.log
print_status $?
printf "    lua"
make generic >> build.log 2>> build.log
print_status $?
cd ..
printf "    luasocket"
printf " ok\n"
printf "    lualogging"
printf " ok\n"
printf "    luanode"
printf " ok\n"

