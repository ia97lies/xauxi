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
  xauxi_dispatcher_t *dispatcher;
} xauxi_listener_t;

typedef struct xauxi_request_s xauxi_request_t;
typedef struct xauxi_connection_s xauxi_connection_t;
struct xauxi_connection_s {
  xauxi_object_t object;
  xauxi_connection_t *counterpart;
  apr_socket_t *socket;
  apr_sockaddr_t *local_addr;
  apr_sockaddr_t *remote_addr;
  xauxi_event_t *event;
  xauxi_dispatcher_t *dispatcher;
  xauxi_request_t *request;
  apr_bucket_alloc_t *alloc;
  apr_bucket_brigade *bb;
  
};

struct xauxi_request_s {
  xauxi_object_t object;
  xauxi_connection_t *frontend;
  xauxi_connection_t *backend;
#define XAUXI_STATE_INIT 0
#define XAUXI_STATE_HEADER 1
#define XAUXI_STATE_BODY 2
  apr_bucket_brigade *line_bb;
  const char *request_line;
  apr_table_t *headers;
  int state;
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
                                        apr_bucket_brigade *bbIn)
{
    apr_off_t readbytes = 0;

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
        readbytes += len;
    }

    return APR_INCOMPLETE;
}

static apr_status_t _notify_request(xauxi_event_t *event) {
  apr_status_t status;
  char buf[XAUXI_BUF_MAX + 1];
  apr_size_t len = XAUXI_BUF_MAX;
  xauxi_request_t *request;

  xauxi_connection_t *connection = xauxi_event_get_custom(event);
  if (!connection->alloc) {
    connection->alloc = apr_bucket_alloc_create(connection->object.pool);
    connection->bb = apr_brigade_create(connection->object.pool, connection->alloc);
  }

  if (!connection->request) {
    apr_pool_t *pool;
    apr_pool_create(&pool, connection->object.pool);
    connection->request = apr_pcalloc(pool, sizeof(xauxi_request_t));
    connection->request->object.pool = pool;
    connection->request->object.name = connection->object.name;
    connection->request->object.L = connection->object.L;
    connection->request->frontend = connection;
    connection->request->headers = apr_table_make(pool, 5);
  }
  request = connection->request;
  
  if ((status = apr_socket_recv(connection->socket, buf, &len)) == APR_SUCCESS) {
    apr_bucket *b;
    b = apr_bucket_heap_create(buf, len, NULL, connection->alloc);
    APR_BRIGADE_INSERT_TAIL(connection->bb, b);
    if (!request->line_bb) {
      request->line_bb = apr_brigade_create(request->object.pool, connection->alloc);
    }
    while ((status = _brigade_split_line(request->line_bb, connection->bb)) 
           == APR_SUCCESS) {
      char *line;
      apr_size_t len;
      apr_brigade_pflatten(request->line_bb, &line, &len, request->object.pool);
      if (len > 1) {
        line[len-2] = 0;
      }
      else if (len > 0) {
        line[len-1] = 0;
      }
      else {
        /* ERROR */
      }
      if (!request->request_line) {
        request->request_line = line;
      }
      else if (line[0]) {
        char *header;
        char *value;
        header = apr_strtok(line, ":", &value); 
        apr_table_add(request->headers, header, value);
      }
      else {
        fprintf(stderr, "request headers read\n");
        /* empty line request headers done */
        /* check for body */
        if (apr_table_get(request->headers, "Content-Length") ||
            _strcasestr(apr_table_get(request->headers, "Transfer-Encoding"), "chunked") ||
            _strcasestr(apr_table_get(request->headers, "Connection"), "close")) {
          fprintf(stderr, "body\n");
        }
        else {
          fprintf(stderr, "no body\n");
          /* connect to a file or backend and register a response event */
          /* link frontend connection and backend connection together */
        }
        lua_getfield(request->object.L, LUA_REGISTRYINDEX, 
                     request->object.name);
        lua_pushlightuserdata(request->object.L, request);
        lua_pcall(request->object.L, 1, LUA_MULTRET, 0);
      }
      apr_brigade_cleanup(request->line_bb);
    }
  }
  else {
    apr_socket_close(connection->socket);
    xauxi_dispatcher_remove_event(connection->dispatcher, connection->event);
  }

  return APR_SUCCESS;
}

static apr_status_t _notify_accept(xauxi_event_t *event) {
  apr_pool_t *pool;
  apr_status_t status;
  xauxi_connection_t *connection;
  xauxi_listener_t *listener = xauxi_event_get_custom(event);

  apr_pool_create(&pool, listener->object.pool);
  connection = apr_pcalloc(pool, sizeof(*connection));
  connection->object.pool = pool;
  connection->object.name = listener->object.name;
  connection->object.L = listener->object.L;
  connection->dispatcher = listener->dispatcher;
  if ((status = apr_socket_accept(&connection->socket, listener->socket,
                                  pool)) == APR_SUCCESS) {
    if ((status = apr_socket_opt_set(connection->socket, APR_TCP_NODELAY, 
                                     1)) == APR_SUCCESS) {
      if ((status = apr_socket_timeout_set(connection->socket, 0)) 
          == APR_SUCCESS) {
        connection->event = xauxi_event_socket(pool, connection->socket);
        xauxi_event_register_read_handle(connection->event, _notify_request); 
        xauxi_event_set_custom(connection->event, connection);
        xauxi_dispatcher_add_event(connection->dispatcher, connection->event);
      }
    }
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
  
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_global");
  global = lua_touserdata(L, -1);
  pool = global->object.pool;
  dispatcher = global->dispatcher;
  lua_pop(L, 1);

  if (lua_isstring(L, 1)) {
    apr_status_t status;
    const char *listen_to;
    apr_sockaddr_t *local_addr;
    xauxi_listener_t *listener = apr_pcalloc(pool, sizeof(*listener));
    listener->object.pool = pool;
    listen_to = lua_tostring(L, 1);
    listener->object.name = listen_to;

    /* on top of stack there is a anonymous function */
    lua_setfield(L, LUA_REGISTRYINDEX, listen_to);

    if ((status = apr_parse_addr_port(&listener->addr, &listener->scope_id, 
                                      &listener->port, listen_to, pool)) 
        != APR_SUCCESS) {
    }
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
        status = apr_socket_opt_set(listener->socket, APR_SO_REUSEADDR, 1);
        if (status == APR_SUCCESS || status == APR_ENOTIMPL) {
          if ((status = apr_socket_bind(listener->socket, local_addr)) 
              == APR_SUCCESS) {
            if ((status = apr_socket_listen(listener->socket, 1)) 
                == APR_SUCCESS) {
              if ((status = apr_socket_timeout_set(listener->socket, 0)) 
                  == APR_SUCCESS) {
                listener->event = xauxi_event_socket(pool, listener->socket);
                listener->object.L = L;
                listener->dispatcher = dispatcher;
                xauxi_event_register_read_handle(listener->event, _notify_accept); 
                xauxi_event_set_custom(listener->event, listener);
                xauxi_dispatcher_add_event(dispatcher, listener->event);
              }
            }
          }
        }
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
  
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_global");
  global = lua_touserdata(L, -1);
  dispatcher = global->dispatcher;
  lua_pop(L, 1);

  for (;;) {
    xauxi_dispatcher_step(dispatcher);
  }

  return 0;
}

/**
 * xauxi dispatcher
 * @param L IN lua state
 * @return 0
 */
static int _connect(lua_State *L) {
  fprintf(stderr, "connect to backend\n");
  if (lua_isuserdata(L, -2)) {
    xauxi_connection_t *frontend;
    apr_pool_t *pool;
    xauxi_request_t *request = lua_touserdata(L, -2);
    frontend = request->frontend;
    if (!frontend->counterpart) {
      xauxi_connection_t *backend;
      apr_pool_create(&pool, frontend->object.pool);
      backend = apr_pcalloc(pool, sizeof(*backend));
      backend->object.pool = pool;
      backend->object.name = request->object.name;
      backend->object.L = request->object.L;
      backend->dispatcher = frontend->dispatcher;
      backend->counterpart = frontend;
      frontend->counterpart = backend;
      request->backend = backend;
    }

    fprintf(stderr, "YEP its %s!!\n", request->object.name);
  }
  /*
  xauxi_global_t *global;
  xauxi_dispatcher_t *dispatcher;
  
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_global");
  global = lua_touserdata(L, -1);
  dispatcher = global->dispatcher;
  lua_pop(L, 1);
  */

  return 0;
}

/**
 * register all needed c functions
 * @param L IN lua state
 * @return apr status
 */
static apr_status_t _register(lua_State *L) {
  lua_pushcfunction(L, _connect);
  lua_setglobal(L, "connect");
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
  if (luaL_loadfile(L, conf) != 0 || lua_pcall(L, 0, LUA_MULTRET, 0) != 0) {
    const char *msg = lua_tostring(L, -1);
    if (msg) {
      fprintf(stderr, "Error: %s\n", msg);
    }
    lua_pop(L, 1);
    return APR_EINVAL;
  }

  lua_getglobal(L, "global");
  if (lua_pcall(L, 0, LUA_MULTRET, 0) != 0) {
    const char *msg = lua_tostring(L, -1);
    if (msg) {
      fprintf(stderr, "Error: %s\n", msg);
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

  luaL_openlibs(L);

  if ((status = _register(L)) != APR_SUCCESS) {
    return status;
  }

  global = apr_pcalloc(pool, sizeof(*global));
  global->object.pool = pool;
  global->dispatcher = xauxi_dispatcher_new(pool, XAUXI_MAX_EVENTS);
  lua_pushlightuserdata(L, global);
  lua_setfield(L, LUA_REGISTRYINDEX, "xauxi_global");

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
