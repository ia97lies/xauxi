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
 * Interface of xauxi event.
 */

#include <apr_pools.h>
#include <apr_poll.h>
#include "xauxi_event.h"

xauxi_event_t *xauxi_event_socket(apr_pool_t *parent, apr_socket_t *socket) {
  apr_pool_t *pool;
  xauxi_event_t *event;

  apr_pool_create(&pool, parent);
  event = apr_pcalloc(pool, sizeof(*event));
  event->pool = pool;
  if (socket) {
    event->pollfd = apr_pcalloc(pool, sizeof(apr_pollfd_t));
    event->pollfd->desc_type = APR_POLL_SOCKET;
    event->pollfd->desc.s = socket;
    event->pollfd->p = pool;
    event->pollfd->client_data = event;
    event->pollfd->reqevents = APR_POLLIN;
  }
  return event;
}

xauxi_event_t *xauxi_event_file(apr_pool_t *parent, apr_file_t *file) {
  apr_pool_t *pool;
  xauxi_event_t *event;

  apr_pool_create(&pool, parent);
  event = apr_pcalloc(pool, sizeof(*event));
  event->pool = pool;
  if (file) {
    event->pollfd = apr_pcalloc(pool, sizeof(apr_pollfd_t));
    event->pollfd->reqevents = APR_POLLIN;
    event->pollfd->desc_type = APR_POLL_FILE;
    event->pollfd->desc.f = file;
    event->pollfd->client_data = event;
  }
  return event;
}

void *xauxi_event_key(xauxi_event_t *event) {
  return &event->pool;
}

apr_size_t xauxi_event_key_len(xauxi_event_t *event) {
  return sizeof(event->pool);
}

apr_pollfd_t *xauxi_event_get_pollfd(xauxi_event_t *event) {
  return event->pollfd;
}

jmp_buf *xauxi_event_get_jmp_buf(xauxi_event_t *event) {
  return &event->env;
}

void xauxi_event_destroy(xauxi_event_t *event) {
  apr_pool_destroy(event->pool);
}

