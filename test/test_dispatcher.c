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
 * Store dispatcher 
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

#include "xauxi_dispatcher.h"

/************************************************************************
 * Defines 
 ***********************************************************************/

/************************************************************************
 * Typedefs 
 ***********************************************************************/

/************************************************************************
 * Implementation 
 ***********************************************************************/
int got_event = 0;
apr_status_t got_event_handle(xauxi_event_t *event) {
  got_event = 1;
  return APR_SUCCESS;
}

int main(int argc, const char *const argv[]) {
  apr_pool_t *pool;
  xauxi_dispatcher_t *dispatcher;

  /** init store */
  apr_app_initialize(&argc, &argv, NULL);
  apr_pool_create(&pool, NULL);
 
  {
    fprintf(stderr, "Create new dispatcher... ");
    dispatcher = xauxi_dispatcher_new(pool, 10000);
    assert(dispatcher != NULL);
    fprintf(stderr, "OK\n");
  }

  {
    xauxi_event_t *event = xauxi_event_socket(pool, NULL);

    fprintf(stderr, "Add event... ");
    xauxi_dispatcher_add_event(dispatcher, event);
    assert(xauxi_dispatcher_get_event(dispatcher, event) != NULL);
    fprintf(stderr, "OK\n");
    fprintf(stderr, "Remove event... ");
    xauxi_dispatcher_remove_event(dispatcher, event);
    assert(xauxi_dispatcher_get_event(dispatcher, event) == NULL);
    fprintf(stderr, "OK\n");
  }

  {
    int i;
#define NO_EVENTS 10000
    xauxi_event_t *event[NO_EVENTS];
    
    fprintf(stderr, "Add %d event... ", NO_EVENTS);
    for(i = 0; i < NO_EVENTS; i++) {
      event[i] = xauxi_event_socket(pool, NULL);
    }
    for(i = 0; i < NO_EVENTS; i++) {
      xauxi_dispatcher_add_event(dispatcher, event[i]);
    }
    fprintf(stderr, "     ");
    for(i = 0; i < NO_EVENTS; i++) {
      fprintf(stderr, "\b\b\b\b\b");
      fprintf(stderr, "%5d", i);
      assert(xauxi_dispatcher_get_event(dispatcher, event[i]) == event[i]);
    }
    fprintf(stderr, " OK\n");
    fprintf(stderr, "Remove %d event... ", NO_EVENTS);
    fprintf(stderr, "     ");
    for(i = 0; i < NO_EVENTS; i++) {
      int j;
      fprintf(stderr, "\b\b\b\b\b");
      fprintf(stderr, "%5d", i);
      xauxi_dispatcher_remove_event(dispatcher, event[i]);
      assert(xauxi_dispatcher_get_event(dispatcher, event[i]) != event[i]);
      for(j = NO_EVENTS-1; j >i; j = j - 10) {
        assert(xauxi_dispatcher_get_event(dispatcher, event[j]) == event[j]);
      }
    }
    fprintf(stderr, " OK\n");
  }

  {
    apr_file_t *file;
    xauxi_event_t *event;

    fprintf(stderr, "Handle file event... ");
    assert(apr_file_open(&file, "/dev/random", APR_READ, APR_OS_DEFAULT, pool) == APR_SUCCESS);
    event = xauxi_event_file(pool, file);
    xauxi_event_register_read_handle(event, got_event_handle); 
    xauxi_dispatcher_add_event(dispatcher, event);

    got_event = 0;
    xauxi_dispatcher_step(dispatcher);
    assert(got_event != 0);

    xauxi_dispatcher_remove_event(dispatcher, event);

    fprintf(stderr, " OK\n");
  }

  {
    xauxi_event_t *event;

    fprintf(stderr, "Handle event timeout... ");
    event = xauxi_event_file(pool, NULL);
    xauxi_event_register_timeout_handle(event, got_event_handle); 
    xauxi_event_set_timeout(event, 1);
    xauxi_dispatcher_add_event(dispatcher, event);

    got_event = 0;
    xauxi_dispatcher_step(dispatcher);
    xauxi_dispatcher_step(dispatcher);
    assert(got_event != 0);

    fprintf(stderr, " OK\n");

  }

  {
    fprintf(stderr, "Destroy dispatcher... ");
    xauxi_dispatcher_destroy(dispatcher);
    fprintf(stderr, "OK\n");
  }

  return 0;
}

