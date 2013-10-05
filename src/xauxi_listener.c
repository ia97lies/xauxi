/**
 * Copyright 2013 Christian Liesch
 *
 * fooLicensed under the Apache License, Version 2.0 (the "License");
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
 * Implementation of the xauxi lua connection object.
 */

/* affects include files on Solaris */
#define BSD_COMP

/************************************************************************
 * Includes
 ***********************************************************************/
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
#include <stdlib.h>
#include <apr.h>
#include <apr_strings.h>
#include <apr_network_io.h>

#define LUA_COMPAT_MODULE
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "xauxi_logger.h"
#include "xauxi_object.h"
#include "xauxi_global.h"
#include "xauxi_event.h"
#include "xauxi_dispatcher.h"
#include "xauxi_logger.h"
#include "xauxi_listener.h"
#include "xauxi_connection.h"

/************************************************************************
 * Defines
 ***********************************************************************/

/************************************************************************
 * Private
 ***********************************************************************/
static apr_status_t _notify_accept(xauxi_event_t *event) {
  apr_pool_t *pool;
  apr_status_t status;
  xauxi_connection_t *connection;
  xauxi_listener_t *listener = xauxi_event_get_custom(event);
  xauxi_logger_t *logger = xauxi_get_logger(listener->object.L);
  xauxi_global_t *global = xauxi_get_global(listener->object.L);

  XAUXI_ENTER_FUNC("_notify_accept");

  xauxi_connection_accept(listener);

  XAUXI_LEAVE_FUNC(APR_SUCCESS);
}

/************************************************************************
 * Public
 ***********************************************************************/
apr_status_t xauxi_listen(xauxi_global_t *global, const char *listen_to) {
  apr_pool_t *pool;
  xauxi_dispatcher_t *dispatcher;
  apr_status_t status;
  apr_sockaddr_t *local_addr;
  xauxi_logger_t *logger;
  xauxi_listener_t *listener;

  pool = global->object.pool;
  dispatcher = global->dispatcher;
  logger = xauxi_get_logger(global->object.L);
  listener = apr_pcalloc(pool, sizeof(*listener));
  listener->object.pool = pool;
  listen_to = lua_tostring(global->object.L, 1);
  listener->object.name = listen_to;

  XAUXI_ENTER_FUNC("xauxi_listen");

  if ((status = apr_parse_addr_port(&listener->addr, &listener->scope_id, 
          &listener->port, listen_to, pool)) 
      == APR_SUCCESS) {
    if (!listener->addr) {
      listener->addr = apr_pstrdup(pool, APR_ANYADDR);
    }
    if (!listener->port) {
      listener->port = 80;
    }
    if ((status = apr_sockaddr_info_get(&local_addr, listener->addr, APR_UNSPEC, 
            listener->port, APR_IPV4_ADDR_OK, pool)) 
        == APR_SUCCESS) {
      if ((status = apr_socket_create(&listener->socket, local_addr->family, 
              SOCK_STREAM, APR_PROTO_TCP, pool)) 
          == APR_SUCCESS) {
        if (local_addr->family == APR_INET) {
          xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "IPv4");
        }
        else {
          xauxi_logger_log(logger, XAUXI_LOG_DEBUG, 0, "IPv6");
        }
        status = apr_socket_opt_set(listener->socket, APR_SO_REUSEADDR, 1);
        if (status == APR_SUCCESS || status == APR_ENOTIMPL) {
          if ((status = apr_socket_opt_set(listener->socket, APR_SO_NONBLOCK, 1))
              == APR_SUCCESS) {
            if ((status = apr_socket_bind(listener->socket, local_addr)) 
                == APR_SUCCESS) {
              if ((status = apr_socket_listen(listener->socket, 1)) 
                  == APR_SUCCESS) {
                listener->event = xauxi_event_socket(pool, listener->socket);
                listener->object.L = global->object.L;
                xauxi_event_register_read_handle(listener->event, _notify_accept); 
                xauxi_event_set_custom(listener->event, listener);
                xauxi_dispatcher_add_event(dispatcher, listener->event);
              }
              else {
                xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                    "Could not listen on %s",
                    listen_to);
                XAUXI_LEAVE_FUNC(status);
              }
            }
            else {
              xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                  "Could not bind to %s",
                  listen_to);
              XAUXI_LEAVE_FUNC(status);
            }
          }
          else {
            xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
                "Could not set nonblock for %s",
                listen_to);
            XAUXI_LEAVE_FUNC(status);
          }
        }
        else {
          xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
              "Could not set reuse address for %s",
              listen_to);
          XAUXI_LEAVE_FUNC(status);
        }
      }
      else {
        xauxi_logger_log(logger, XAUXI_LOG_ERR, status, 
            "Could not create listener socket for %s",
            listen_to);
        XAUXI_LEAVE_FUNC(status);
      }
    }
    else {
      xauxi_logger_log(logger, XAUXI_LOG_ERR, status, "Could not resolve %s",
          listen_to);
      XAUXI_LEAVE_FUNC(status);
    }
  }
  XAUXI_LEAVE_FUNC(0);
}
