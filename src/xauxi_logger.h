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
 * Interface of the HTTP Test Tool logger
 */

#ifndef XAUXI_LOGGER_H
#define XAUXI_LOGGER_H

#define XAUXI_LOG_NONE 0 
#define XAUXI_LOG_ERR 1
#define XAUXI_LOG_WARN 2
#define XAUXI_LOG_INFO 3
#define XAUXI_LOG_DEBUG 4
#define XAUXI_LOG_DEBUG_HIGH 5

#include "xauxi_appender.h"

typedef struct xauxi_logger_s xauxi_logger_t;

xauxi_logger_t *xauxi_logger_new(apr_pool_t *pool, int mode);
xauxi_logger_t *xauxi_logger_clone(apr_pool_t *pool, xauxi_logger_t *origin, 
                                   int id);
void xauxi_logger_set_appender(xauxi_logger_t *logger, 
                               xauxi_appender_t *appender, const char *name, 
                               int from_mode, int to_mode); 
void xauxi_logger_del_appender(xauxi_logger_t *logger, const char *name); 
void xauxi_logger_set_group(xauxi_logger_t *logger, int group);
void xauxi_logger_log_va(xauxi_logger_t *logger, int log_mode, 
                         apr_status_t status, char *fmt, va_list va);
void xauxi_logger_log(xauxi_logger_t * logger, int log_mode, 
                      apr_status_t status, char *fmt, ...);
void xauxi_logger_log_buf(xauxi_logger_t * logger, int mode, char dir, 
                          const char *buf, apr_size_t len); 
void xauxi_logger_set_mode(xauxi_logger_t *logger, int mode);
int xauxi_logger_get_mode(xauxi_logger_t *logger);


#endif
