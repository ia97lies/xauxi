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
 * Implementation of the xauxi lua global object.
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

#include "xauxi_global.h"

/************************************************************************
 * Defines
 ***********************************************************************/

/************************************************************************
 * Private
 ***********************************************************************/

/************************************************************************
 * Public
 ***********************************************************************/
xauxi_global_t *xauxi_get_global(lua_State *L) {
  xauxi_global_t *global;
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_global");
  global = lua_touserdata(L, -1);
  lua_pop(L, 1);
  return global;
}

xauxi_logger_t *xauxi_get_logger(lua_State *L) {
  xauxi_logger_t *logger;
  lua_getfield(L, LUA_REGISTRYINDEX, "xauxi_logger");
  logger = lua_touserdata(L, -1);
  lua_pop(L, 1);
  return logger;
}

