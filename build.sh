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
printf "    boost"
printf " ok\n"
printf "    lua"
printf " ok\n"
printf "    luasocket"
printf " ok\n"
printf "    lualogging"
printf " ok\n"
printf "    luanode"
printf " ok\n"

