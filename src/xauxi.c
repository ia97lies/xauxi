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

#include <pcre.h>

#if APR_HAVE_UNISTD_H
#include <unistd.h> /* for getpid() */
#endif

#define LUA_COMPAT_MODULE
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>


/************************************************************************
 * Defines 
 ***********************************************************************/

/************************************************************************
 * Structurs
 ***********************************************************************/
typedef struct xauxi_object_s {
  apr_pool_t *pool;
  apr_table_t *container;
  const char *name;
} xauxi_object_t;

typedef struct xauxi_session_s {
  xauxi_object_t object;
  apr_size_t id;
} xauxi_session_t;

typedef struct xauxi_request_s {
  xauxi_object_t object;
  xauxi_session_t *session;
  apr_table_t *headers_in;
  apr_table_t *headers_out;
} xauxi_request_t;

typedef struct xauxi_location_s {
  xauxi_object_t object;
} xauxi_location_t;

typedef struct xauxi_server_s {
  xauxi_object_t object;
} xauxi_server_t;

typedef struct xauxi_global_s {
  xauxi_object_t object;
  xauxi_server_t *cur_server;
} xauxi_global_t;

/************************************************************************
 * Globals 
 ***********************************************************************/

apr_getopt_option_t options[] = {
  { "version", 'V', 0, "Print version number and exit" },
  { "help", 'h', 0, "Display usage information (this message)" },
  { "root", 'd', 1, "Xauxi root root" },
  { "config", 'c', 1, "Xauxi configuration file" },
  { NULL, 0, 0, NULL }
};

/************************************************************************
 * Privates
 ***********************************************************************/
/**
 * xauxi server
 * @param L IN lua state
 * @return 0
 */
static int xauxi_server (lua_State *L) {
  int rc;
  const char *name;
  xauxi_global_t *global;
  xauxi_server_t *server;
  apr_pool_t *pool;
 
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_global");
  global = lua_touserdata(L, -1);
  lua_pop(L, 1);

  if (lua_isstring(L, 1)) {
    name = lua_tostring(L, 1);

    apr_pool_create(&pool, global->object.pool);
    server = apr_pcalloc(pool, sizeof(*server));
    server->object.name = apr_pstrdup(pool, name);
    server->object.container = apr_table_make(pool, 5);
    server->object.pool = pool;

    global->cur_server = server;
    apr_table_addn(global->object.container, server->object.name, (void*)server);

    fprintf(stdout, "  server %s\n", name);
    if ((rc = lua_pcall(L, 0, LUA_MULTRET, 0)) != 0) {
      const char *msg = lua_tostring(L, -1);
      if (msg) {
        luaL_argerror(L, 1, msg);
      }
      else {
        luaL_argerror(L, 1, "unknown server error");
      }
    }
  }
  else {
    luaL_argerror(L, 1, "server name expected");
    return 1;
  }
  return 0;
}

/**
 * xauxi location
 * @param L IN lua state
 * @return 0
 */
static int xauxi_location (lua_State *L) {
  const char *name;
  const char *unique;
  apr_pool_t *pool;
  xauxi_server_t *location;
  xauxi_server_t *server;
  xauxi_global_t *global;
  
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_global");
  global = lua_touserdata(L, -1);
  lua_pop(L, 1);

  if (lua_isstring(L, 1)) {
    name = lua_tostring(L, 1);

    /* on top of stack there is a anonymous function */
    server = global->cur_server;
    unique = apr_pstrcat(server->object.pool, server->object.name, name, NULL);
    lua_setfield(L, LUA_REGISTRYINDEX, unique);

    fprintf(stdout, "    location %s\n", unique);

    apr_pool_create(&pool, server->object.pool);
    location = apr_pcalloc(pool, sizeof(*location));
    location->object.name = apr_pstrdup(pool, name);
    location->object.pool = pool;

    apr_table_addn(server->object.container, location->object.name, (void*)location);
  }
  else {
    luaL_argerror(L, 1, "location name expected");
  }
  return 0;
}

/**
 * Pass content from one side to the oder and vise versa
 * @param L IN lua state
 * @return 0
 */
static int xauxi_pass (lua_State *L) {
  const char *name = lua_tostring(L, 1);
  fprintf(stdout, "      pass %s\n", name);
  return 0;
}

/**
 * register all needed c functions
 * @param L IN lua state
 * @return apr status
 */
static apr_status_t xauxi_register(lua_State *L) {
  lua_pushcfunction(L, xauxi_server);
  lua_setglobal(L, "server");
  lua_pushcfunction(L, xauxi_location);
  lua_setglobal(L, "location");
  lua_pushcfunction(L, xauxi_pass);
  lua_setglobal(L, "pass");
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
 * xauxi main loop to handle connections
 * @param L IN lua state
 * @param global IN global context
 * @return apr status
 */
apr_status_t xauxi_main_loop(lua_State *L, xauxi_global_t *global) {
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
  global->object.container = apr_table_make(pool, 5);
  lua_pushlightuserdata(L, global);
  lua_setfield(L, LUA_REGISTRYINDEX, "xauxi_global");

  if ((status = xauxi_read_config(L, conf)) != APR_SUCCESS) {
    return status;
  }

  if ((status = xauxi_main_loop(L, global)) != APR_SUCCESS) {
    return status;
  }

  lua_getfield(L, LUA_REGISTRYINDEX, "http://localhost:8080/foo");
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
