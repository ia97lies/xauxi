all: build test
build: setup
test: start check stop

setup:
	./setup.sh

start:
	cd test; ./start.sh; sleep 1

stop:
	cd test; ./stop.sh

killall:
	killall luanode

check:
	cd test; ./run.sh "" integration/*.htt
