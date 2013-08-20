/**
 * Copyright 2006 Christian Liesch
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
 * Interface of the HTTP Test Tool log appender
 */

#ifndef XAUXI_APPENDER_H
#define XAUXI_APPENDER_H

typedef struct xauxi_appender_s xauxi_appender_t;
typedef void (*printer_f)(xauxi_appender_t *appender, int mode, 
                          apr_status_t status, char dir, 
                          const char *buf, apr_size_t len);

xauxi_appender_t *xauxi_appender_new(apr_pool_t *pool, printer_f printer, 
                                     void *user_data);
void *xauxi_appender_get_user_data(xauxi_appender_t *appender);
void xauxi_appender_set_mutex(xauxi_appender_t *appender, 
                              apr_thread_mutex_t *mutex); 
apr_thread_mutex_t *xauxi_appender_get_mutex(xauxi_appender_t *appender); 
void xauxi_appender_lock(xauxi_appender_t *appender); 
void xauxi_appender_unlock(xauxi_appender_t *appender);
void xauxi_appender_print(xauxi_appender_t *appender, int mode, 
                          apr_status_t status, char dir, 
                          const char *buf, apr_size_t len);

#endif
