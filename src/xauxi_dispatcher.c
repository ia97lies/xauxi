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
#include "xauxi_dispatcher.h"

struct xauxi_dispatcher_s {
  apr_pool_t *pool;
  apr_uint32_t size;
  apr_pollset_t *pollset;
  apr_hash_t *events;
};

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

void xauxi_dispatcher_step(xauxi_dispatcher_t *dispatcher) {
  int i;
  apr_int32_t num;
  const apr_pollfd_t *descriptors;
  apr_pollset_poll(dispatcher->pollset, apr_time_from_sec(1), &num, &descriptors);
  for (i = 0; i < num; i++) {
    apr_time_t now = apr_time_now();
    xauxi_event_t *event = descriptors[i].client_data;
    xauxi_event_set_modify(event, now);
    if (descriptors[i].rtnevents & APR_POLLIN) {
      xauxi_event_notify_read(event);
    }
    if (descriptors[i].rtnevents & APR_POLLOUT) {
      xauxi_event_notify_write(event);
    }
    if (descriptors[i].rtnevents & APR_POLLHUP) {
      xauxi_event_notify_close(event);
    }
    if (descriptors[i].rtnevents & APR_POLLERR) {
      xauxi_event_notify_error(event);
    }
  }
  /* update all descriptors idle time and notify/close timeouted events */
  {
    apr_pool_t *ptmp;
    apr_hash_index_t *hi;
    apr_time_t now = apr_time_now();

    apr_pool_create(&ptmp, dispatcher->pool);
    for (hi = apr_hash_first(ptmp, dispatcher->events); hi; hi = apr_hash_next(hi)) {
      void *val;
      xauxi_event_t *event;
      apr_hash_this(hi, NULL, NULL, &val);
      event = val;
      if (xauxi_event_get_timeout(event) != 0 &&
          now - xauxi_event_get_modify(event) > xauxi_event_get_timeout(event)) {
        xauxi_event_notify_timeout(event);
      }
    }
    apr_pool_destroy(ptmp);
  }

}

void xauxi_dispatcher_destroy(xauxi_dispatcher_t *dispatcher) {
  apr_pool_destroy(dispatcher->pool);
}

