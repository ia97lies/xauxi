#!/bin/bash

../src/xauxi --root ../test/simple --lib ../lib > xauxi.log &

for i in `ls *.htt`; do
  ./run.sh -Te $i
done
