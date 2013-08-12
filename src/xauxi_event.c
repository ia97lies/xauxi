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

struct xauxi_event_s {
  apr_time_t modify;
  apr_time_t timeout;
  apr_pool_t *pool;
  apr_pollfd_t *pollfd;
  notify_read_f notify_read;
  notify_timeout_f notify_timeout;
}; 

static xauxi_event_t *xauxi_event_new(apr_pool_t *parent) {
  apr_pool_t *pool;
  xauxi_event_t *event;

  apr_pool_create(&pool, parent);
  event = apr_pcalloc(pool, sizeof(*event));
  event->pool = pool;
  event->timeout = -1;
  return event;
}

xauxi_event_t *xauxi_event_socket(apr_pool_t *parent, apr_socket_t *socket) {
  xauxi_event_t *event = xauxi_event_new(parent);
  if (socket) {
    event->pollfd = apr_pcalloc(event->pool, sizeof(apr_pollfd_t));
    event->pollfd->p = event->pool;
    event->pollfd->reqevents = APR_POLLIN;
    event->pollfd->desc_type = APR_POLL_SOCKET;
    event->pollfd->desc.s = socket;
    event->pollfd->client_data = event;
  }
  return event;
}

xauxi_event_t *xauxi_event_file(apr_pool_t *parent, apr_file_t *file) {
  xauxi_event_t *event = xauxi_event_new(parent);
  if (file) {
    event->pollfd = apr_pcalloc(event->pool, sizeof(apr_pollfd_t));
    event->pollfd->p = event->pool;
    event->pollfd->reqevents = APR_POLLIN;
    event->pollfd->desc_type = APR_POLL_FILE;
    event->pollfd->desc.f = file;
    event->pollfd->client_data = event;
  }
  return event;
}

void xauxi_event_register_read_handle(xauxi_event_t *event, notify_read_f notify_read) {
  event->notify_read = notify_read;
}

void xauxi_event_register_timeout_handle(xauxi_event_t *event, notify_timeout_f notify_timeout) {
  event->notify_timeout = notify_timeout;
}

void xauxi_event_set_timeout(xauxi_event_t *event, apr_time_t timeout) {
  event->timeout = timeout;
}

apr_time_t xauxi_event_get_timeout(xauxi_event_t *event) {
  return event->timeout;
}

void xauxi_event_set_modify(xauxi_event_t *event, apr_time_t time) {
  event->modify = time;
}

apr_time_t xauxi_event_get_modify(xauxi_event_t *event) {
  return event->modify;
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

void xauxi_event_destroy(xauxi_event_t *event) {
  apr_pool_destroy(event->pool);
}

void xauxi_event_notify_read(xauxi_event_t *event) {
  if (event->notify_read) {
    event->notify_read(event);
  }
}

void xauxi_event_notify_timeout(xauxi_event_t *event) {
  if (event->notify_timeout) {
    event->notify_timeout(event);
  }
}

