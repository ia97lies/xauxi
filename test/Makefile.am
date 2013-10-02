EXTRA_DIST= connection.lua request.lua http.lua \
	    simple.htt simple_concurrent.htt
lua_unit_SOURCES=lua_unit.c
lua_unit_CFLAGS=-DTOP="\"$(top_srcdir)\""
test_event_SOURCES=test_event.c $(top_srcdir)/src/xauxi_event.c
test_dispatcher_SOURCES=test_dispatcher.c $(top_srcdir)/src/xauxi_dispatcher.c $(top_srcdir)/src/xauxi_event.c
AM_CFLAGS=-I$(top_srcdir)/src
check_PROGRAMS=test_event test_dispatcher lua_unit
TESTS=test_event test_dispatcher connection.lua request.lua http.lua run_httest.sh
