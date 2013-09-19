/* contributor license agreements. 
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
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
 * Lua unit tests
 */

/* affects include files on Solaris */
#define BSD_COMP

/************************************************************************
 * Includes
 ***********************************************************************/
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
#include <stdio.h>
#include <assert.h>

#include <apr.h>
#include <apr_pools.h>
#include <apr_strings.h>

#define LUA_COMPAT_MODULE
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

/************************************************************************
 * Defines 
 ***********************************************************************/

/************************************************************************
 * Typedefs 
 ***********************************************************************/

/************************************************************************
 * Implementation 
 ***********************************************************************/
int main(int argc, const char *const argv[]) {
  apr_pool_t *pool;
  lua_State *L;
  /** init store */
  apr_app_initialize(&argc, &argv, NULL);
  apr_pool_create(&pool, NULL);

  L = luaL_newstate();
  luaL_openlibs(L);

  lua_getglobal( L, "package" );
  lua_getfield( L, -1, "path" );
  lua_pop( L, 1 );
  lua_pushstring( L, TOP"/lib/?.lua");
  lua_setfield( L, -2, "path" );
  lua_pop( L, 1 );

  if (luaL_loadfile(L, argv[1]) != 0 || lua_pcall(L, 0, LUA_MULTRET, 0) != 0) {
    const char *msg = lua_tostring(L, -1);
    if (msg) {
      fprintf(stderr, "Test failed: %s\n", msg);
    }
    lua_pop(L, 1);
    return -1;
  }

  lua_getglobal(L, "test");
  if (lua_pcall(L, 0, LUA_MULTRET, 0) != 0) {
    const char *msg = lua_tostring(L, -1);
    if (msg) {
      fprintf(stderr, "Test failed: %s\n", msg);
    }
    lua_pop(L, 1);
    return -1;
  }
  else {
    int fail = lua_tointeger(L, -1);
    int run = lua_tointeger(L, -2);
    fprintf(stdout, "run: %d, fail: %d\n", run, fail);
    fflush(stdout);
    if (fail) {
      return -1;
    }
  }

  return 0;
}

