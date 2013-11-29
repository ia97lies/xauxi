all: setup
test: start unit integration stop

setup:
	./setup.sh

start:
	cd test; ./start.sh; sleep 1

stop:
	cd test; ./stop.sh

clean: killall
killall:
	killall xauxi

unit:
	cd test; ./run_unit.sh
integration:
	cd test; ./run_integration.sh
