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
typedef struct xauxi_connection_s {
  xauxi_object_t object;
  apr_socket_t *socket;
  apr_sockaddr_t *local_addr;
  apr_sockaddr_t *remote_addr;
  xauxi_event_t *event;
  xauxi_dispatcher_t *dispatcher;
  xauxi_request_t *request;
} xauxi_connection_t;

struct xauxi_request_s {
  xauxi_object_t object;
  xauxi_connection_t *connection;
#define XAUXI_STATE_INIT 0
#define XAUXI_STATE_HEADER 1
#define XAUXI_STATE_BODY 2
  apr_bucket_alloc_t *alloc;
  apr_bucket_brigade *bb;
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
static apr_status_t xauxi_notify_request(xauxi_event_t *event) {
  char buf[XAUXI_BUF_MAX + 1];
  char *line;
  apr_size_t len = XAUXI_BUF_MAX;

  xauxi_connection_t *connection = xauxi_event_get_custom(event);
  apr_socket_recv(connection->socket, buf, &len);

  if (!connection->request) {
    apr_pool_t *pool;
    apr_pool_create(&pool, connection->object.pool);
    connection->request = apr_pcalloc(pool, sizeof(xauxi_request_t));
    connection->request->object.pool = pool;
    connection->request->object.name = connection->object.name;
    connection->request->alloc = apr_bucket_alloc_create(pool);
    connection->request->bb = apr_brigade_create(pool, connection->request->alloc);
  }
  


  lua_getfield(connection->object.L, LUA_REGISTRYINDEX, 
               connection->object.name);
  lua_pcall(connection->object.L, 0, LUA_MULTRET, 0);
  return APR_SUCCESS;
}

static apr_status_t xauxi_notify_accept(xauxi_event_t *event) {
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
        xauxi_event_register_read_handle(connection->event, xauxi_notify_request); 
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
static int xauxi_listen (lua_State *L) {
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
                xauxi_event_register_read_handle(listener->event, xauxi_notify_accept); 
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
static int xauxi_go (lua_State *L) {
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
 * register all needed c functions
 * @param L IN lua state
 * @return apr status
 */
static apr_status_t xauxi_register(lua_State *L) {
  lua_pushcfunction(L, xauxi_listen);
  lua_setglobal(L, "listen");
  lua_pushcfunction(L, xauxi_go);
  lua_setglobal(L, "go");
  return APR_SUCCESS;
}

/**
 * read configuration
 * @param L IN lua state
 * @param conf IN configuration file
 * @return apr status
 */
static apr_status_t xauxi_read_config(lua_State *L, const char *conf) {
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
static apr_status_t xauxi_main(const char *root, apr_pool_t *pool) {
  apr_status_t status;
  lua_State *L = luaL_newstate();
  const char *conf = apr_pstrcat(pool, root, "/conf/xauxi.lua", NULL);
  xauxi_global_t *global;

  luaL_openlibs(L);

  if ((status = xauxi_register(L)) != APR_SUCCESS) {
    return status;
  }

  global = apr_pcalloc(pool, sizeof(*global));
  global->object.pool = pool;
  global->dispatcher = xauxi_dispatcher_new(pool, XAUXI_MAX_EVENTS);
  lua_pushlightuserdata(L, global);
  lua_setfield(L, LUA_REGISTRYINDEX, "xauxi_global");

  if ((status = xauxi_read_config(L, conf)) != APR_SUCCESS) {
    return status;
  }

  return APR_SUCCESS;
}


/** 
 * display usage information
 * @progname IN name of the programm
 */
static void usage() {
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
      usage();
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
  if ((status = xauxi_main(root, pool)) != APR_SUCCESS) {
    exit(1);
  }

  return 0;
}
