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
#include "xauxi_connection.h"

/************************************************************************
 * Defines
 ***********************************************************************/
#define XAUXI_LUA_CONNECTION "xauxi.connection"
#define XAUXI_LUA_WRITE_COMPLETION "writeCompletionHandler"

/************************************************************************
 * Private
 ***********************************************************************/
static apr_status_t _notify_write_data(xauxi_event_t *event) {
  apr_status_t status;
  xauxi_connection_t *connection = xauxi_event_get_custom(event);
  xauxi_logger_t *logger = xauxi_get_logger(connection->object.L);
  xauxi_global_t *global = xauxi_get_global(connection->object.L);
  size_t len = connection->buffer.len - connection->buffer.cur;

  XAUXI_ENTER_FUNC("_notify_write_data");

  xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "_notify_write_data");
  if ((status = apr_socket_send(connection->socket, 
                                &connection->buffer.data[connection->buffer.cur], 
                                &len)) == APR_SUCCESS) {
    xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "wrote %d bytes", len);
    connection->buffer.cur += len;
    /* if we are done remove all */
    if (connection->buffer.cur == connection->buffer.len) {
      xauxi_dispatcher_remove_event(global->dispatcher, connection->event);
      /* remove only write notify */
      xauxi_event_get_pollfd(connection->event)->reqevents &= ~APR_POLLOUT;
      if (xauxi_event_get_pollfd(connection->event)->reqevents) {
        xauxi_dispatcher_add_event(global->dispatcher, connection->event);
      }
    }
  }
  else {
    xauxi_logger_log(logger, XAUXI_LOG_ERR, status, "Error on write");
  }

  XAUXI_LEAVE_FUNC(APR_SUCCESS);
}

static xauxi_connection_t *_connection_pget(lua_State *L, int i) {
  if (luaL_checkudata(L, i, XAUXI_LUA_CONNECTION) == NULL) {
    luaL_argerror(L, 1, "invalid object type");
  }
  return lua_touserdata(L, i);
}

static int _connection_tostring(lua_State *L) {
  xauxi_connection_t *connection = _connection_pget(L, 1);
  xauxi_logger_t *logger = xauxi_get_logger(L);

  XAUXI_ENTER_FUNC("_connection_tostring");
  lua_pushstring(L, connection->object.name);
  XAUXI_LEAVE_LUA_FUNC(1);
}

static int _connection_batch_write(lua_State *L) {
  xauxi_connection_t *connection = _connection_pget(L, 1);
  xauxi_global_t *global = xauxi_get_global(L);
  xauxi_logger_t *logger = xauxi_get_logger(L);

  XAUXI_ENTER_FUNC("_connection_tostring");
  if (lua_isstring(L, -1)) {
    size_t len;
    const char *buf = lua_tolstring(L, -1, &len);

    /* maybe this is a problem, as I do not know when Lua do free
     * the passed string, I should use brigade to hold and send
     * the data */
    connection->buffer.data = buf;
    connection->buffer.len = len;
    connection->buffer.cur = 0;
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
  XAUXI_LEAVE_LUA_FUNC(0);
}


struct luaL_Reg connection_methods[] = {
  { "__tostring", _connection_tostring },
  { "tostring", _connection_tostring },
  { "batchWrite", _connection_batch_write },
  {NULL, NULL},
};

/************************************************************************
 * Public
 ***********************************************************************/
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

