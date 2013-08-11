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
 * Interface of xauxi dispatcher 
 */

#ifndef XAUXI_DISPATCHER_H
#define XAUXI_DISPATCHER_H

#include <apr_pools.h>
#include <apr_time.h>
#include "xauxi_event.h"

typedef struct xauxi_dispatcher_s xauxi_dispatcher_t;
typedef void (*main_f)(void *custom);
xauxi_dispatcher_t *xauxi_dispatcher_new(apr_pool_t *parent, apr_uint32_t size); 
void xauxi_dispatcher_add_event(xauxi_dispatcher_t *dispatcher, xauxi_event_t *event);
void xauxi_dispatcher_remove_event(xauxi_dispatcher_t *dispatcher, xauxi_event_t *event); 
xauxi_event_t *xauxi_dispatcher_get_event(xauxi_dispatcher_t *dispatcher, xauxi_event_t *event);
void xauxi_dispatcher_destroy(xauxi_dispatcher_t *dispatcher);
void xauxi_dispatcher_loop(xauxi_dispatcher_t *dispatcher, main_f main, void *custom); 

#endif
