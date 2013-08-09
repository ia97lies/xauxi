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
 * Store unit test 
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

#include "xauxi_event.h"

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
  xauxi_event_t *event;

  /** init store */
  apr_app_initialize(&argc, &argv, NULL);
  apr_pool_create(&pool, NULL);
 
  fprintf(stdout, "Create event... ");
  event = xauxi_event_socket(pool, NULL);
  assert(event != NULL);
  fprintf(stdout, "OK\n");

  fprintf(stdout, "Destroy event... ");
  xauxi_event_destroy(event);
  fprintf(stdout, "OK\n");
  return 0;
}

