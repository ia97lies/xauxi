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
 * Interface of xauxi global
 */

#ifndef XAUXI_GLOBAL_H
#define XAUXI_GLOBAL_H

#include "xauxi_object.h"
#include "xauxi_logger.h"
#include "xauxi_dispatcher.h"

typedef struct xauxi_global_s {
  xauxi_object_t object;
  xauxi_dispatcher_t *dispatcher;
} xauxi_global_t;

xauxi_global_t *xauxi_get_global(lua_State *L); 
xauxi_logger_t *xauxi_get_logger(lua_State *L); 

#endif
