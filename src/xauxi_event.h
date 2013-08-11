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

#ifndef XAUXI_EVENT_H
#define XAUXI_EVENT_H

#include <apr_pools.h>
#include <apr_poll.h>
#include <setjmp.h>

typedef struct xauxi_event_s xauxi_event_t;

struct xauxi_event_s {
  apr_pool_t *pool;
  apr_pollfd_t *pollfd;
  jmp_buf env;
}; 

xauxi_event_t *xauxi_event_socket(apr_pool_t *parent, apr_socket_t *socket);
xauxi_event_t *xauxi_event_file(apr_pool_t *parent, apr_file_t *file);
void *xauxi_event_key(xauxi_event_t *event); 
apr_size_t xauxi_event_key_len(xauxi_event_t *event); 
apr_pollfd_t *xauxi_event_get_pollfd(xauxi_event_t *event); 
void xauxi_event_destroy(xauxi_event_t *event); 

#endif
