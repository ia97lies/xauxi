/**
 * Copyright 2013 Christian Liesch
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
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
 * Interface of xauxi event handling.
 */

#include <apr_pools.h>
#include <apr_poll.h>
#include <apr_hash.h>
#include <setjmp.h>
#include "xauxi_dispatcher.h"

struct xauxi_dispatcher_s {
  apr_pool_t *pool;
  jmp_buf env;
  jmp_buf terminate;
  apr_uint32_t size;
  apr_pollset_t *pollset;
  apr_hash_t *events;
};

void xauxi_dispatcher_cycle(xauxi_dispatcher_t *dispatcher) {
  if (setjmp(dispatcher->env) != 0) {
    for (;;) {
      int i;
      apr_int32_t num;
      const apr_pollfd_t *descriptors;
      apr_pollset_poll(dispatcher->pollset, apr_time_from_sec(1), &num, &descriptors);
      for (i = 0; i < num; i++) {
        if (setjmp(dispatcher->env) == 0) {
          xauxi_event_t *event = descriptors[i].client_data;
          xauxi_event_longjmp(event);
        }
      }
      /* update all descriptors idle time and notify/close timeouted events */
    }
  }
  else {
    setjmp(dispatcher->terminate); 
  }
}

xauxi_dispatcher_t *xauxi_dispatcher_new(apr_pool_t *parent, apr_uint32_t size) {
  apr_pool_t *pool;
  xauxi_dispatcher_t *dispatcher;
  apr_status_t status;

  apr_pool_create(&pool, parent);
  dispatcher = apr_pcalloc(pool, sizeof(*dispatcher));
  dispatcher->pool = pool;
  dispatcher->events = apr_hash_make(pool);
  if ((status = apr_pollset_create(&dispatcher->pollset, size, pool, APR_POLLSET_NOCOPY)) != APR_SUCCESS) {
    return NULL;
  } 
  xauxi_dispatcher_cycle(dispatcher);
  return dispatcher;
}

void xauxi_dispatcher_add_event(xauxi_dispatcher_t *dispatcher, xauxi_event_t *event) {
  apr_pollfd_t *pollfd = xauxi_event_get_pollfd(event);
  if (pollfd) {
    apr_pollset_add(dispatcher->pollset, pollfd);
  }
  apr_hash_set(dispatcher->events, xauxi_event_key(event), xauxi_event_key_len(event), event);
}

void xauxi_dispatcher_remove_event(xauxi_dispatcher_t *dispatcher, xauxi_event_t *event) {
  apr_pollfd_t *pollfd = xauxi_event_get_pollfd(event);
  if (pollfd) {
    apr_pollset_remove(dispatcher->pollset, xauxi_event_get_pollfd(event));
  }
  apr_hash_set(dispatcher->events, xauxi_event_key(event), xauxi_event_key_len(event), NULL);
}

xauxi_event_t *xauxi_dispatcher_get_event(xauxi_dispatcher_t *dispatcher, xauxi_event_t *event) {
  return apr_hash_get(dispatcher->events, xauxi_event_key(event), xauxi_event_key_len(event));
}

void xauxi_dispatcher_wait(xauxi_dispatcher_t *dispatcher, xauxi_event_t *event) {
  if (xauxi_event_setjmp(event) == 0) {
    longjmp(dispatcher->env, 1);
  }
}

void xauxi_dispatcher_terminate(xauxi_dispatcher_t *dispatcher) {
  longjmp(dispatcher->terminate, 1);
}

void xauxi_dispatcher_destroy(xauxi_dispatcher_t *dispatcher) {
  apr_pool_destroy(dispatcher->pool);
}

