all: build test
build: stage setup
test: start check stop

setup:
	./setup.sh

stage:
	./stage.sh

start:
	cd test; ./start.sh; sleep 1

stop:
	cd test; ./stop.sh

killall:
	killall luanode

check:
	cd test; ./run.sh "" *.htt
