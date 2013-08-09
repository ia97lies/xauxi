test_event_SOURCES=test_event.c $(top_srcdir)/src/xauxi_event.c
test_dispatcher_SOURCES=test_dispatcher.c $(top_srcdir)/src/xauxi_dispatcher.c $(top_srcdir)/src/xauxi_event.c
AM_CFLAGS=-I$(top_srcdir)/src
check_PROGRAMS=test_event test_dispatcher
TESTS=test_event test_dispatcher
