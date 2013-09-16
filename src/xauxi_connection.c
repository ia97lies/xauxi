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

#include <apr.h>
#include <apr_network_io.h>

#define LUA_COMPAT_MODULE
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "xauxi_object.h"
#include "xauxi_dispatcher.h"
#include "xauxi_logger.h"
#include "xauxi_connection.h"

/************************************************************************
 * Defines
 ***********************************************************************/
#define XAUXI_LUA_CONNECTION "xauxi.connection"

/************************************************************************
 * Private
 ***********************************************************************/
static xauxi_connection_t *_connection_pget(lua_State *L, int i) {
  if (luaL_checkudata(L, i, XAUXI_LUA_CONNECTION) == NULL) {
    luaL_argerror(L, 1, "invalid object type");
  }
  return lua_touserdata(L, i);
}

static int _connection_tostring(lua_State *L) {
  xauxi_connection_t *connection = _connection_pget(L, 1);
  lua_pushstring(L, connection->object.name);
  return 1;
}

static int _connection_get_request(lua_State *L) {
  lua_pushnil(L);
  return 1;
}


struct luaL_Reg connection_methods[] = {
  { "__tostring", _connection_tostring },
  { "tostring", _connection_tostring },
  { "getRequest", _connection_get_request },
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

