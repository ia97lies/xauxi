/**
 * Copyright 2013 Christian Liesch
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
 * Implementation of the xauxi lua connection object.
 */

/* affects include files on Solaris */
#define BSD_COMP

/************************************************************************
 * Includes
 ***********************************************************************/
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
#include <stdlib.h>
#include <apr.h>
#include <apr_network_io.h>

#define LUA_COMPAT_MODULE
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "xauxi_logger.h"
#include "xauxi_object.h"
#include "xauxi_global.h"
#include "xauxi_event.h"
#include "xauxi_dispatcher.h"
#include "xauxi_logger.h"
#include "xauxi_listener.h"
#include "xauxi_connection.h"

/************************************************************************
 * Defines
 ***********************************************************************/
struct xauxi_connection_s {
  xauxi_object_t object;
  apr_socket_t *socket;
  apr_sockaddr_t *local_addr;
  apr_sockaddr_t *remote_addr;
  xauxi_event_t *event;
  apr_bucket_alloc_t *alloc;
  apr_bucket_brigade *buffer;
  int is_closed;
};

#define XAUXI_LUA_CONNECTION "xauxi.connection"
#define XAUXI_LUA_WRITE_COMPLETION "writeCompletionHandler"

/************************************************************************
 * Private
 ***********************************************************************/
static apr_status_t _notify_read_data(xauxi_event_t *event) {
  apr_status_t status;
  char buf[XAUXI_BUF_MAX + 1];
  apr_size_t len = XAUXI_BUF_MAX;
  xauxi_connection_t *connection = xauxi_event_get_custom(event);
  xauxi_logger_t *logger = xauxi_get_logger(connection->object.L);
  xauxi_global_t *global = xauxi_get_global(connection->object.L);

  XAUXI_ENTER_FUNC("_notify_read_data");

  if ((status = apr_socket_recv(connection->socket, buf, &len)) == APR_SUCCESS) {
    xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Got %d bytes", len);
    /* TODO: this belongs to where this function was setup as there the
     *       number of args/rets are wellknown */
    lua_getfield(connection->object.L, LUA_REGISTRYINDEX,
        connection->object.name);
    lua_pushlightuserdata(connection->object.L, connection);
    luaL_getmetatable(connection->object.L, XAUXI_LUA_CONNECTION);
    lua_setmetatable(connection->object.L, -2);
    lua_pushlstring(connection->object.L, buf, len);
    if (lua_pcall(connection->object.L, 2, LUA_MULTRET, 0) != 0) {
      const char *msg = lua_tostring(connection->object.L, -1);
      if (msg) {
        xauxi_logger_log(logger, XAUXI_LOG_ERR, APR_EGENERAL, "%s", msg);
      }
      lua_pop(connection->object.L, 1);
      XAUXI_LEAVE_FUNC(APR_EINVAL);
    }
  }
  else {
    xauxi_logger_log(logger, XAUXI_LOG_DEBUG, status, "Connection close");
    /* TODO: this belongs to where this function was setup as there the
     *       number of args/rets are wellknown */
    lua_getfield(connection->object.L, LUA_REGISTRYINDEX,
        connection->object.name);
    lua_pushlightuserdata(connection->object.L, connection);
    luaL_getmetatable(connection->object.L, XAUXI_LUA_CONNECTION);
    lua_setmetatable(connection->object.L, -2);
    lua_pushnil(connection->object.L);
    if (lua_pcall(connection->object.L, 2, LUA_MULTRET, 0) != 0) {
      const char *msg = lua_tostring(connection->object.L, -1);
      if (msg) {
        xauxi_logger_log(logger, XAUXI_LOG_ERR, APR_EGENERAL, "%s", msg);
      }
      lua_pop(connection->object.L, 1);
      XAUXI_LEAVE_FUNC(APR_EINVAL);
    }
    xauxi_dispatcher_remove_event(global->dispatcher, connection->event);
    xauxi_event_destroy(connection->event);
    apr_socket_close(connection->socket);
    connection->is_closed = 1;
  }
  XAUXI_LEAVE_FUNC(APR_SUCCESS);
}

static apr_status_t _notify_write_data(xauxi_event_t *event) {
  apr_status_t status;
  xauxi_connection_t *connection = xauxi_event_get_custom(event);
  xauxi_logger_t *logger = xauxi_get_logger(connection->object.L);
  xauxi_global_t *global = xauxi_get_global(connection->object.L);

  XAUXI_ENTER_FUNC("_notify_write_data");

  if (!APR_BRIGADE_EMPTY(connection->buffer) && !connection->is_closed) {
    size_t len;
    const char *buf;
    apr_size_t buf_len;
    apr_bucket *e;

    e = APR_BRIGADE_FIRST(connection->buffer);
    apr_bucket_read(e, &buf, &buf_len, APR_NONBLOCK_READ);
    len = buf_len;
    if ((status = apr_socket_send(connection->socket, buf, &len)) 
        == APR_SUCCESS) {
      xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "buf len is %d, wrote %d bytes", buf_len, len);
      if (len < buf_len) {
        apr_bucket_split(e, buf_len - len + 1);
      }
      APR_BUCKET_REMOVE(e);
      apr_bucket_destroy(e);
    }
    else {
      xauxi_logger_log(logger, XAUXI_LOG_ERR, status, "Error on write");
    }
  }
  else {
    xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "write finished");
    xauxi_dispatcher_remove_event(global->dispatcher, connection->event);
    /* remove only write notify */
    xauxi_event_get_pollfd(connection->event)->reqevents &= ~APR_POLLOUT;
    if (xauxi_event_get_pollfd(connection->event)->reqevents) {
      xauxi_dispatcher_add_event(global->dispatcher, connection->event);
    }
    if (connection->is_closed) {
      xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Destroy connection on write");
      apr_pool_destroy(connection->object.pool);
    }
  }

  XAUXI_LEAVE_FUNC(APR_SUCCESS);
}

static xauxi_connection_t *_connection_new(xauxi_object_t *object) {
  apr_pool_t *pool;
  xauxi_connection_t *connection;
  apr_pool_create(&pool, object->pool);
  connection = apr_pcalloc(pool, sizeof(*connection));
  connection->object.pool = pool;
  connection->object.name = object->name;
  connection->object.L = object->L;
  connection->alloc = apr_bucket_alloc_create(pool);
  connection->buffer = apr_brigade_create(pool, connection->alloc);
  return connection;
}

static int _connection_tostring(lua_State *L) {
  xauxi_connection_t *connection = xauxi_connection_pget(L, 1);
  xauxi_logger_t *logger = xauxi_get_logger(L);

  XAUXI_ENTER_FUNC("_connection_tostring");
  lua_pushstring(L, connection->object.name);
  XAUXI_LEAVE_LUA_FUNC(1);
}

static int _connection_write(lua_State *L) {
  xauxi_connection_t *connection = xauxi_connection_pget(L, 1);
  xauxi_global_t *global = xauxi_get_global(L);
  xauxi_logger_t *logger = xauxi_get_logger(L);

  XAUXI_ENTER_FUNC("_connection_write");
  if (!connection->is_closed) {
    if (lua_isstring(L, -1)) {
      size_t len;
      const char *buf = lua_tolstring(L, -1, &len);

      apr_brigade_write(connection->buffer, NULL, NULL, buf, len);
      if (!connection->event) {
        connection->event = xauxi_event_socket(connection->object.pool, 
            connection->socket);
      }
      xauxi_dispatcher_remove_event(global->dispatcher, connection->event);
      /* add write notify */
      xauxi_event_get_pollfd(connection->event)->reqevents |= APR_POLLOUT;
      xauxi_event_register_write_handle(connection->event, _notify_write_data); 
      xauxi_event_set_custom(connection->event, connection);
      xauxi_dispatcher_add_event(global->dispatcher, connection->event);
    }
    else {
      xauxi_logger_log(logger, XAUXI_LOG_ERR, APR_EGENERAL, "No bufer to write");
    }
  }
  else {
    xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Destroy connection on write");
    apr_pool_destroy(connection->object.pool);
  }
  XAUXI_LEAVE_LUA_FUNC(0);
}

static int _connection_read(lua_State *L) {
  xauxi_connection_t *connection = xauxi_connection_pget(L, 1);
  xauxi_global_t *global = xauxi_get_global(L);
  xauxi_logger_t *logger = xauxi_get_logger(L);

  XAUXI_ENTER_FUNC("_connection_read");
  if (!connection->is_closed) {
    if (!connection->event) {
      connection->event = xauxi_event_socket(connection->object.pool, 
          connection->socket);
    }
    xauxi_dispatcher_remove_event(global->dispatcher, connection->event);
    /* add read notify */
    xauxi_event_get_pollfd(connection->event)->reqevents |= APR_POLLIN;
    xauxi_event_register_read_handle(connection->event, _notify_read_data); 
    xauxi_event_set_custom(connection->event, connection);
    xauxi_dispatcher_add_event(global->dispatcher, connection->event);
  }
  else {
    xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Destroy connection on write");
    apr_pool_destroy(connection->object.pool);
  }
  XAUXI_LEAVE_LUA_FUNC(0);
}


struct luaL_Reg connection_methods[] = {
  { "__tostring", _connection_tostring },
  { "tostring", _connection_tostring },
  { "write", _connection_write },
  { "read", _connection_read },
  {NULL, NULL},
};

/************************************************************************
 * Public
 ***********************************************************************/
xauxi_connection_t *xauxi_connection_pget(lua_State *L, int i) {
  if (luaL_checkudata(L, i, XAUXI_LUA_CONNECTION) == NULL) {
    luaL_argerror(L, 1, "invalid object type");
  }
  return lua_touserdata(L, i);
}

const char *xauxi_connection_get_name(xauxi_connection_t *connection) {
  return connection->object.name;
}

void xauxi_connection_connect(xauxi_object_t *object, const char *connect_to) {
  apr_pool_t *pool;
  apr_status_t status;
  xauxi_connection_t *connection;
  char *addr;
  char *scope_id;
  apr_port_t port;
  apr_sockaddr_t *sa;

  xauxi_logger_t *logger = xauxi_get_logger(object->L);

  connection = _connection_new(object);
  pool = connection->object.pool;
  if ((status = apr_parse_addr_port(&addr, &scope_id, &port, connect_to, pool))
      == APR_SUCCESS) {
    if ((status = apr_sockaddr_info_get(&sa, addr, APR_UNSPEC, port, 
            APR_IPV4_ADDR_OK, pool)) == APR_SUCCESS) {
      if ((status = apr_socket_create(&connection->socket, APR_INET, SOCK_STREAM,
              APR_PROTO_TCP, pool)) == APR_SUCCESS) {
        if ((status = apr_socket_opt_set(connection->socket, APR_TCP_NODELAY, 
                1)) == APR_SUCCESS) {
          if ((status = apr_socket_timeout_set(connection->socket, 0)) 
              == APR_SUCCESS) {
            status = apr_socket_connect(connection->socket, sa); 
            if (APR_STATUS_IS_EINPROGRESS(status)) {
              /* TODO: store backend address in connection and log it */
              xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Connection request pending");
              /* TODO: this belongs to where this function was setup as there the
               *       number of args/rets are wellknown */
              lua_getfield(connection->object.L, LUA_REGISTRYINDEX,
                  connection->object.name);
              lua_pushlightuserdata(connection->object.L, connection);
              luaL_getmetatable(connection->object.L, XAUXI_LUA_CONNECTION);
              lua_setmetatable(connection->object.L, -2);
              if (lua_pcall(connection->object.L, 1, LUA_MULTRET, 0) != 0) {
                const char *msg = lua_tostring(connection->object.L, -1);
                if (msg) {
                  xauxi_logger_log(logger, XAUXI_LOG_ERR, APR_EGENERAL, "%s", msg);
                }
                lua_pop(connection->object.L, 1);
              }
            }
            else {
              xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                  "Could not connect to remote host %s:%d", addr, port);
            }
          }
          else {
            xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                "Could not set socket nonblocking");
          }
        }
        else {
          xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
              "Could not set socket to nodelay");
        }
      }
      else {
        xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
            "Could not create connection");
      }
    }
    else {
      xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
          "Could not resolve hostname %s", addr);
    }
  }
  else {
    xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
        "Could not parse hostname \"%s\" to connect to", connect_to);
  }
}

void xauxi_connection_accept(xauxi_listener_t *listener) {
  apr_pool_t *pool;
  apr_status_t status;
  xauxi_connection_t *connection;

  xauxi_logger_t *logger = xauxi_get_logger(listener->object.L);
  xauxi_global_t *global = xauxi_get_global(listener->object.L);

  connection = _connection_new(&listener->object);
  pool = connection->object.pool;
  if ((status = apr_socket_accept(&connection->socket, listener->socket,
                                  pool)) == APR_SUCCESS) {
    if ((status = apr_socket_opt_set(connection->socket, APR_TCP_NODELAY, 
                                     1)) == APR_SUCCESS) {
      if ((status = apr_socket_timeout_set(connection->socket, 0)) 
          == APR_SUCCESS) {
        /* TODO: store client address in connection and log it */
        xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "Accept connection");
        connection->event = xauxi_event_socket(pool, connection->socket);
        xauxi_event_get_pollfd(connection->event)->reqevents = APR_POLLIN | APR_POLLERR;
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
}

void xauxi_connection_lib_open(lua_State *L) {
  luaL_newmetatable (L, XAUXI_LUA_CONNECTION);
  
  /* define methods */
  luaL_openlib (L, NULL, connection_methods, 0);
  
  /* define metamethods */
  lua_pushliteral (L, "__index");
  lua_pushvalue (L, -2);
  lua_settable (L, -3);

  lua_pushliteral (L, "__metatable");
  lua_pushliteral (L, "xauxi: you're not allowed to get this metatable");
  lua_settable (L, -3);
}

