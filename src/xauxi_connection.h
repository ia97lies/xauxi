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
 * Interface of xauxi connection
 */

#ifndef XAUXI_CONNECTION_H
#define XAUXI_CONNECTION_H

typedef struct xauxi_connection_s xauxi_connection_t;
struct xauxi_connection_s {
  xauxi_object_t object;
  apr_socket_t *socket;
  apr_sockaddr_t *local_addr;
  apr_sockaddr_t *remote_addr;
  xauxi_event_t *event;
};

void xauxi_connection_lib_open(lua_State *L); 

#endif
