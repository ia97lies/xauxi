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
#include <setjmp.h>
#include "xauxi_dispatcher.h"

struct xauxi_dispatcher_s {
  apr_pool_t *pool;
  jmp_buf env;
  apr_pollset_t *pollset;
};

xauxi_dispatcher_t *xauxi_dispatcher_new(apr_pool_t *pool, apr_uint32_t size) {
  apr_status_t status;
  xauxi_dispatcher_t *dispatcher = apr_pcalloc(pool, sizeof(*dispatcher));
  dispatcher->pool = pool;
  if ((status = apr_pollset_create(&dispatcher->pollset, size, pool, 0)) != APR_SUCCESS) {
    return NULL;
  } 
  return dispatcher;
}

void xauxi_dispatcher_cycle(xauxi_dispatcher_t *dispatcher, apr_time_t timeout) {
  int i;
  apr_int32_t num;
  apr_status_t status;
  const apr_pollfd_t *descriptors;
  status = apr_pollset_poll(dispatcher->pollset, timeout, &num, &descriptors);
  for (i = 0; i < num; i++) {
    if (setjmp(dispatcher->env) == 0) {
      descriptors[i];
      /* longjmp to descriptor */
    }
  }
  /* update all descriptors idle time and notify/close timeouted events */
}

