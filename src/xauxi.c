/**
 * Copyright 2012 Christian Liesch
 *
 * fooLicensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @file
 *
 * @Author christian liesch <liesch@gmx.ch>
 *
 * Implementation of the lua based reverse proxy xauxi.
 */

/* affects include files on Solaris */
#define BSD_COMP

/************************************************************************
 * Includes
 ***********************************************************************/
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

/* Use STACK from openssl to sort commands */
#include <openssl/ssl.h>

#include <apr.h>
#include <apr_signal.h>
#include <apr_strings.h>
#include <apr_network_io.h>
#include <apr_file_io.h>
#include <apr_time.h>
#include <apr_getopt.h>
#include <apr_general.h>
#include <apr_lib.h>
#include <apr_portable.h>
#include <apr_support.h>
#include <apr_hash.h>
#include <apr_env.h>
#include <apr_buckets.h>

#include <pcre.h>

#if APR_HAVE_UNISTD_H
#include <unistd.h> /* for getpid() */
#endif

#define LUA_COMPAT_MODULE
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "xauxi_dispatcher.h"
#include "xauxi_logger.h"
#include "xauxi_appender_log.h"

/************************************************************************
 * Defines 
 ***********************************************************************/
#define XAUXI_MAX_EVENTS 15000
/************************************************************************
 * Structurs
 ***********************************************************************/
typedef struct xauxi_object_s {
  apr_pool_t *pool;
  const char *name;
  lua_State *L;
} xauxi_object_t;

typedef struct xauxi_global_s {
  xauxi_object_t object;
  xauxi_dispatcher_t *dispatcher;
} xauxi_global_t;

typedef struct xauxi_listener_s {
  xauxi_object_t object;
  apr_socket_t *socket;
  apr_sockaddr_t *local_addr;
  char *addr;
  char *scope_id;
  apr_port_t port;
  xauxi_event_t *event;
} xauxi_listener_t;

typedef struct xauxi_request_s xauxi_request_t;
typedef struct xauxi_connection_s xauxi_connection_t;
struct xauxi_connection_s {
  xauxi_object_t object;
  apr_socket_t *socket;
  apr_sockaddr_t *local_addr;
  apr_sockaddr_t *remote_addr;
  xauxi_event_t *event;
  apr_bucket_alloc_t *alloc;
  apr_bucket_brigade *bb;
};

struct xauxi_request_s {
  xauxi_object_t object;
  xauxi_connection_t *frontend;
  xauxi_connection_t *backend;
  apr_bucket_brigade *line_bb;
  const char *first_line;
  apr_table_t *headers;
#define XAUXI_REQUEST_HAS_NONE 0x0000
#define XAUXI_REQUEST_HAS_BODY 0x0001
#define XAUXI_REQUEST_CHUNKED  0x0002
#define XAUXI_REQUEST_CONTENT_LENGTH 0x0004
#define XAUXI_REQUEST_CONNECTION_CLOSE 0x0008
  int flags;
};

/************************************************************************
 * Globals 
 ***********************************************************************/
#define XAUXI_BUF_MAX 8192

apr_getopt_option_t options[] = {
  { "version", 'V', 0, "Print version number and exit" },
  { "help", 'h', 0, "Display usage information (this message)" },
  { "root", 'd', 1, "Xauxi root root" },
  { NULL, 0, 0, NULL }
};

/************************************************************************
 * Privates
 ***********************************************************************/
static xauxi_global_t *_get_global(lua_State *L) {
  xauxi_global_t *global;
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_global");
  global = lua_touserdata(L, -1);
  lua_pop(L, 1);
  return global;
}

static xauxi_logger_t *_get_logger(lua_State *L) {
  xauxi_logger_t *logger;
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_logger");
  logger = lua_touserdata(L, -1);
  lua_pop(L, 1);
  return logger;
}

/* a copy of strstr implementation */
static char *_strcasestr(const char *s1, const char *s2) {
  char *p1, *p2;
  if (!s1 || !s2) {
    return NULL;
  }
  if (*s2 == '\0') {
    /* an empty s2 */
    return((char *)s1);
  }
  while(1) {
    for ( ; (*s1 != '\0') && (apr_tolower(*s1) != apr_tolower(*s2)); s1++);
      if (*s1 == '\0') {
	return(NULL);
      }
      /* found first character of s2, see if the rest matches */
      p1 = (char *)s1;
      p2 = (char *)s2;
      for (++p1, ++p2; apr_tolower(*p1) == apr_tolower(*p2); ++p1, ++p2) {
	if (*p1 == '\0') {
	  /* both strings ended together */
	  return((char *)s1);
	}
      }
      if (*p2 == '\0') {
	/* second string ended, a match */
	break;
      }
      /* didn't find a match here, try starting at next character in s1 */
      s1++;
  }
  return((char *)s1);
}

/* a copy of apr_brigade_split_line */
static apr_status_t _brigade_split_line(apr_bucket_brigade *bbOut,
    apr_bucket_brigade *bbIn) {
  while (!APR_BRIGADE_EMPTY(bbIn)) {
    const char *pos;
    const char *str;
    apr_size_t len;
    apr_status_t rv;
    apr_bucket *e;

    e = APR_BRIGADE_FIRST(bbIn);
    rv = apr_bucket_read(e, &str, &len, APR_NONBLOCK_READ);

    if (rv != APR_SUCCESS) {
      return rv;
    }

    pos = memchr(str, APR_ASCII_LF, len);
    /* We found a match. */
    if (pos != NULL) {
      apr_bucket_split(e, pos - str + 1);
      APR_BUCKET_REMOVE(e);
      APR_BRIGADE_INSERT_TAIL(bbOut, e);
      return APR_SUCCESS;
    }
    APR_BUCKET_REMOVE(e);
    if (APR_BUCKET_IS_METADATA(e) || len > APR_BUCKET_BUFF_SIZE/4) {
      APR_BRIGADE_INSERT_TAIL(bbOut, e);
    }
    else {
      if (len > 0) {
        rv = apr_brigade_write(bbOut, NULL, NULL, str, len);
        if (rv != APR_SUCCESS) {
          return rv;
        }
      }
      apr_bucket_destroy(e);
    }
  }

  return APR_INCOMPLETE;
}

static apr_status_t _notify_read_data(xauxi_event_t *event) {
  apr_status_t status;
  char buf[XAUXI_BUF_MAX + 1];
  apr_size_t len = XAUXI_BUF_MAX;
  xauxi_request_t *request;
  xauxi_connection_t *connection = xauxi_event_get_custom(event);
  xauxi_logger_t *logger = _get_logger(connection->object.L);
  xauxi_global_t *global = _get_global(connection->object.L);

  xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Read data");
  if (!connection->alloc) {
    connection->alloc = apr_bucket_alloc_create(connection->object.pool);
    connection->bb = apr_brigade_create(connection->object.pool, connection->alloc);
  }

  if ((status = apr_socket_recv(connection->socket, buf, &len)) == APR_SUCCESS) {
    apr_bucket *b;
    b = apr_bucket_heap_create(buf, len, NULL, connection->alloc);
    APR_BRIGADE_INSERT_TAIL(connection->bb, b);
    xauxi_logger_log(logger, XAUXI_LOG_DEBUG_HIGH, 0, "Got %d bytes", len);
    /* TODO: call handler */

  }
  else {
    xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Connection close to frontend");
    apr_socket_close(connection->socket);
    xauxi_dispatcher_remove_event(global->dispatcher, connection->event);
    xauxi_event_destroy(connection->event);
    apr_pool_destroy(connection->object.pool);
  }
  return APR_SUCCESS;
}

static apr_status_t _notify_accept(xauxi_event_t *event) {
  apr_pool_t *pool;
  apr_status_t status;
  xauxi_connection_t *connection;
  xauxi_listener_t *listener = xauxi_event_get_custom(event);
  xauxi_logger_t *logger = _get_logger(listener->object.L);
  xauxi_global_t *global = _get_global(listener->object.L);

  apr_pool_create(&pool, listener->object.pool);
  connection = apr_pcalloc(pool, sizeof(*connection));
  connection->object.pool = pool;
  connection->object.name = listener->object.name;
  connection->object.L = listener->object.L;
  if ((status = apr_socket_accept(&connection->socket, listener->socket,
                                  pool)) == APR_SUCCESS) {
    if ((status = apr_socket_opt_set(connection->socket, APR_TCP_NODELAY, 
                                     1)) == APR_SUCCESS) {
      if ((status = apr_socket_timeout_set(connection->socket, 0)) 
          == APR_SUCCESS) {
        /* TODO: store client address in connection and log it */
        xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Accept connection");
        connection->event = xauxi_event_socket(pool, connection->socket);
        xauxi_event_get_pollfd(connection->event)->reqevents = APR_POLLIN;
        xauxi_event_register_read_handle(connection->event, _notify_read_data); 
        xauxi_event_set_custom(connection->event, connection);
        xauxi_dispatcher_add_event(global->dispatcher, connection->event);
      }
      else {
        xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                         "Could not set connection nonblocking");
      }
    }
    else {
      xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                       "Could not set accepted connection to nodelay");
    }
  }
  else {
    xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                     "Could not accept connection");
  }

  return APR_SUCCESS;
}

/**
 * xauxi location
 * @param L IN lua state
 * @return 0
 */
static int _listen (lua_State *L) {
  xauxi_global_t *global;
  apr_pool_t *pool;
  xauxi_dispatcher_t *dispatcher;
  
  global = _get_global(L);
  pool = global->object.pool;
  dispatcher = global->dispatcher;

  if (lua_isstring(L, 1)) {
    apr_status_t status;
    const char *listen_to;
    apr_sockaddr_t *local_addr;
    xauxi_listener_t *listener = apr_pcalloc(pool, sizeof(*listener));
    xauxi_logger_t *logger = _get_logger(L);
    listener->object.pool = pool;
    listen_to = lua_tostring(L, 1);
    listener->object.name = listen_to;

    xauxi_logger_log(logger, XAUXI_LOG_INFO, 0, "Listen to %s", listen_to);
    /* on top of stack there is a anonymous function */
    lua_setfield(L, LUA_REGISTRYINDEX, listen_to);

    if ((status = apr_parse_addr_port(&listener->addr, &listener->scope_id, 
            &listener->port, listen_to, pool)) 
        == APR_SUCCESS) {
      if (!listener->addr) {
        listener->addr = apr_pstrdup(pool, APR_ANYADDR);
      }
      if (!listener->port) {
        listener->port = 80;
      }
      if ((status = apr_sockaddr_info_get(&local_addr, listener->addr, APR_UNSPEC, 
              listener->port, APR_IPV4_ADDR_OK, pool)) 
          == APR_SUCCESS) {
        if ((status = apr_socket_create(&listener->socket, local_addr->family, 
                SOCK_STREAM, APR_PROTO_TCP, pool)) 
            == APR_SUCCESS) {
          if (local_addr->family == APR_INET) {
            xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "IPv4");
          }
          else {
            xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "IPv6");
          }
          status = apr_socket_opt_set(listener->socket, APR_SO_REUSEADDR, 1);
          if (status == APR_SUCCESS || status == APR_ENOTIMPL) {
            if ((status = apr_socket_opt_set(listener->socket, APR_SO_NONBLOCK, 1))
                == APR_SUCCESS) {
              if ((status = apr_socket_bind(listener->socket, local_addr)) 
                  == APR_SUCCESS) {
                if ((status = apr_socket_listen(listener->socket, 1)) 
                    == APR_SUCCESS) {
                  listener->event = xauxi_event_socket(pool, listener->socket);
                  listener->object.L = L;
                  xauxi_event_register_read_handle(listener->event, _notify_accept); 
                  xauxi_event_set_custom(listener->event, listener);
                  xauxi_dispatcher_add_event(dispatcher, listener->event);
                }
                else {
                  xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                                   "Could not listen on %s",
                                   listen_to);
                }
              }
              else {
                xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                                 "Could not bind to %s",
                                 listen_to);
              }
            }
            else {
              xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                               "Could not set nonblock for %s",
                               listen_to);
            }
          }
          else {
            xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                             "Could not set reuse address for %s",
                             listen_to);
          }
        }
        else {
          xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                           "Could not create listener socket for %s",
                           listen_to);
        }
      }
      else {
        xauxi_logger_log(logger, XAUXI_LOG_ERR, status, "Could not resolve %s",
                         listen_to);
      }
    }
  }
  else {
    luaL_argerror(L, 1, "listen address expected");
  }
  return 0;
}

/**
 * xauxi go 
 * @param L IN lua state
 * @return 0
 */
static int _go (lua_State *L) {
  xauxi_global_t *global;
  xauxi_dispatcher_t *dispatcher;
  xauxi_logger_t *logger = _get_logger(L);
  
  global = _get_global(L);
  dispatcher = global->dispatcher;

  xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "start dispatching");
  for (;;) {
    xauxi_dispatcher_step(dispatcher);
  }

  return 0;
}

/**
 * register all needed c functions
 * @param L IN lua state
 * @return apr status
 */
static apr_status_t _register(lua_State *L) {
  lua_pushcfunction(L, _listen);
  lua_setglobal(L, "listen");
  lua_pushcfunction(L, _go);
  lua_setglobal(L, "go");
  return APR_SUCCESS;
}

/**
 * read configuration
 * @param L IN lua state
 * @param conf IN configuration file
 * @return apr status
 */
static apr_status_t _read_config(lua_State *L, const char *conf) {
  xauxi_logger_t *logger = _get_logger(L);
  if (luaL_loadfile(L, conf) != 0 || lua_pcall(L, 0, LUA_MULTRET, 0) != 0) {
    const char *msg = lua_tostring(L, -1);
    if (msg) {
      xauxi_logger_log(logger, XAUXI_LOG_ERR, APR_EGENERAL, "%s", msg);
    }
    lua_pop(L, 1);
    return APR_EINVAL;
  }

  lua_getglobal(L, "global");
  if (lua_pcall(L, 0, LUA_MULTRET, 0) != 0) {
    const char *msg = lua_tostring(L, -1);
    if (msg) {
      xauxi_logger_log(logger, XAUXI_LOG_ERR, APR_EGENERAL, "%s", msg);
    }
    lua_pop(L, 1);
    return APR_EINVAL;
  }
  return APR_SUCCESS;
}

/**
 * xauxi main loop
 * @param root IN root directory
 * @param pool IN global pool
 * @return APR_SUCCESS or any apr error
 */
static apr_status_t _main(const char *root, apr_pool_t *pool) {
  apr_status_t status;
  lua_State *L = luaL_newstate();
  const char *conf = apr_pstrcat(pool, root, "/conf/xauxi.lua", NULL);
  xauxi_global_t *global;
  xauxi_logger_t *logger;
  xauxi_appender_t *appender;
  apr_file_t *out;

  luaL_openlibs(L);

  if ((status = _register(L)) != APR_SUCCESS) {
    return status;
  }

  global = apr_pcalloc(pool, sizeof(*global));
  global->object.pool = pool;
  global->dispatcher = xauxi_dispatcher_new(pool, XAUXI_MAX_EVENTS);
  lua_pushlightuserdata(L, global);
  lua_setfield(L, LUA_REGISTRYINDEX, "xauxi_global");

  apr_file_open_stdout(&out, pool);
  logger = xauxi_logger_new(pool, XAUXI_LOG_DEBUG_HIGH);
  appender = xauxi_appender_log_new(pool, out); 
  xauxi_logger_set_appender(logger, appender, "log", 0, XAUXI_LOG_DEBUG_HIGH);
  lua_pushlightuserdata(L, logger);
  lua_setfield(L, LUA_REGISTRYINDEX, "xauxi_logger");

  xauxi_logger_log(logger, XAUXI_LOG_INFO, 0, "Start xauxi "VERSION);

  if ((status = _read_config(L, conf)) != APR_SUCCESS) {
    return status;
  }

  return APR_SUCCESS;
}


/** 
 * display usage information
 * @progname IN name of the programm
 */
static void _usage() {
  int i = 0;

  fprintf(stdout, "xauxi is a lua base reverse proxy\n");
  fprintf(stdout, "\nUsage: xauxi [OPTIONS] scripts\n");
  fprintf(stdout, "\nOptions:");
  while (options[i].optch) {
    if (options[i].optch <= 255) {
      fprintf(stdout, "\n  -%c --%-15s %s", options[i].optch, options[i].name,
	      options[i].description);
    }
    else {
      fprintf(stdout, "\n     --%-15s %s", options[i].name, 
	      options[i].description);
    }
    i++;
  }

  fprintf(stdout, "\n");
  fprintf(stdout, "\nReport bugs to http://sourceforge.net/projects/xauxi");
  fprintf(stdout, "\n");
}

/**
 * display copyright information
 * @param program name
 */
void copyright() {
  printf("xauxi " PACKAGE_VERSION "\n");
  printf("\nCopyright (C) 2012 Free Software Foundation, Inc.\n"
         "This is free software; see the source for copying conditions.  There is NO\n"
	 "warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n");
  printf("\nWritten by Christian Liesch\n");
}

/** 
 * get args and start xauxi main loop
 * @param argc IN number of arguments
 * @param argv IN argument array
 * @return 0 if success
 */
int main(int argc, const char *const argv[]) {
  apr_status_t status;
  apr_getopt_t *opt;
  const char *optarg;
  int c;
  apr_pool_t *pool;
  const char *root;

  srand(apr_time_now()); 
  
  apr_app_initialize(&argc, &argv, NULL);
  apr_pool_create(&pool, NULL);

  /* block broken pipe signal */
#if !defined(WIN32)
  apr_signal_block(SIGPIPE);
#endif
  
  /* set default */
  root = apr_pstrdup(pool, ".");

  /* create a global vars table */

  /* get options */
  apr_getopt_init(&opt, pool, argc, argv);
  while ((status = apr_getopt_long(opt, options, &c, &optarg)) == APR_SUCCESS) {
    switch (c) {
    case 'h':
      _usage();
      exit(0);
      break;
    case 'V':
      copyright();
      exit(0);
      break;
    case 'd':
      root = apr_pstrdup(pool, optarg);
      break;
    }
  }

  /* test for wrong options */
  if (!APR_STATUS_IS_EOF(status)) {
    fprintf(stderr, "try \"xauxi --help\" to get more information\n");
    exit(1);
  }

  /* try open <root>/conf/xauxi.lua */
  if ((status = _main(root, pool)) != APR_SUCCESS) {
    exit(1);
  }

  return 0;
}
