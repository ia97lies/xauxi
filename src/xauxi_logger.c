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
 * Implementation of the HTTP Test Tool logger.
 */

/************************************************************************
 * Includes
 ***********************************************************************/
#include <config.h>
#include <apr.h>
#include <apr_strings.h>
#include <apr_file_io.h>
#include <apr_env.h>

#include <apr.h>
#include <apr_lib.h>
#include <apr_errno.h>
#include <apr_strings.h>
#include <apr_portable.h>
#include <apr_hash.h>
#include <apr_base64.h>
#include <apr_hooks.h>
#include <apr_env.h>

#include "xauxi_logger.h"
#include "xauxi_appender.h"


/************************************************************************
 * Definitions 
 ***********************************************************************/
typedef struct xauxi_logger_entry_s {
  int lo_mode;
  int hi_mode;
  xauxi_appender_t *appender;
} xauxi_logger_entry_t;

struct xauxi_logger_s {
  apr_pool_t *pool;
  int mode;
  int group;
  apr_table_t *appenders;
  int lo_mode;
  int hi_mode;
  xauxi_appender_t *appender;
};

/************************************************************************
 * Forward declaration 
 ***********************************************************************/
static void xauxi_logger_print(xauxi_logger_t *logger, int mode, 
                               apr_status_t status, char dir,
                               const char *buf, apr_size_t len);

/************************************************************************
 * Implementation
 ***********************************************************************/

/**
 * Constructor for logger
 * @param pool IN pool
 * @param mode IN logger mode set outside
 * @param id IN thread id 
 * @return logger
 */
xauxi_logger_t *xauxi_logger_new(apr_pool_t *pool, int mode) {
  xauxi_logger_t *logger = apr_pcalloc(pool, sizeof(*logger));
  logger->mode = mode;
  logger->pool = pool;
  logger->appenders = apr_table_make(pool, 5);

  return logger;
}

/**
 * Add an appender
 * @param logger IN instance
 * @param appender IN appender to add
 * @param name IN appender name
 * @param lo_mode IN the higgest mode
 * @param hi_mode IN the lowest mode
 */
void xauxi_logger_set_appender(xauxi_logger_t *logger, 
                               xauxi_appender_t *appender, const char *name, 
                               int lo_mode, int hi_mode) {
  xauxi_logger_entry_t *entry = apr_pcalloc(logger->pool, sizeof(*entry));
  entry->lo_mode = lo_mode;
  entry->hi_mode = hi_mode;
  entry->appender = appender;
  apr_table_setn(logger->appenders, apr_pstrdup(logger->pool, name), 
                 (void *)entry);
}

/**
 * Delete given appender
 * @param logger IN instance
 * @param name IN name of appender to delete
 */
void xauxi_logger_del_appender(xauxi_logger_t *logger, const char *name) {
  apr_table_unset(logger->appenders, name);
}

static void xauxi_logger_print(xauxi_logger_t *logger, int mode, 
                               apr_status_t status, char dir, const char *buf, 
                               apr_size_t len) {
  int i;
  apr_table_entry_t *e;

  e = (apr_table_entry_t *) apr_table_elts(logger->appenders)->elts;
  for (i = 0; i < apr_table_elts(logger->appenders)->nelts; ++i) {
    xauxi_logger_entry_t *le = (void *)e[i].val;
    if (mode <= le->hi_mode && mode >= le->lo_mode) {
      xauxi_appender_print(le->appender, mode, status, dir, buf, len);
    }
  }
}

/**
 * a simple log mechanisme with va args
 * @param logger IN thread data object
 * @param status IN status, APR_SUCCESS will be silent
 * @param mode IN log mode
 *                XAUXI_LOG_DEBUG for a lot of infos
 *                XAUXI_LOG_INFO for much infos
 *                XAUXI_LOG_ERR for only very few infos
 * @param fmt IN printf format string
 * @param va IN params for format strings as va_list
 */
void xauxi_logger_log_va(xauxi_logger_t * logger, int mode, apr_status_t status,
                         char *fmt, va_list va) {
  if (logger->mode >= mode) {
    char *tmp;
    apr_pool_t *pool;

    apr_pool_create(&pool, NULL);
    tmp = apr_pvsprintf(pool, fmt, va);
    xauxi_logger_print(logger, mode, status, '=', tmp, strlen(tmp));
    apr_pool_destroy(pool);
  }
}
 
/**
 * log formated 
 * @param worker IN thread data object
 * @param mode IN log mode
 *                XAUXI_LOG_DEBUG for a lot of infos
 *                XAUXI_LOG_INFO for much infos
 *                XAUXI_LOG_ERR for only very few infos
 * @param status IN status, APR_SUCCESS will be silent
 * @param fmt IN printf format string
 * @param ... IN params for format strings
 */

void xauxi_logger_log(xauxi_logger_t * logger, int log_mode, 
                      apr_status_t status, char *fmt, ...) {
  va_list va;
  va_start(va, fmt);
  xauxi_logger_log_va(logger, log_mode, status, fmt, va);
  va_end(va);
}

/**
 * a simple log buf mechanisme
 * @param logger IN thread data object
 * @param mode IN log mode
 *                XAUXI_LOG_DEBUG for a lot of infos
 *                XAUXI_LOG_INFO for much infos
 *                XAUXI_LOG_ERR for only very few infos
 * @param dir IN <,>,+,=
 * @param buf IN buf to print (binary data allowed)
 * @param len IN buf len
 */
void xauxi_logger_log_buf(xauxi_logger_t * logger, int mode, char dir, 
                          const char *buf, apr_size_t len) {

  if (logger->mode >= mode) {
    if (buf && !len) {
      len = strlen(buf);
    }
    xauxi_logger_print(logger, mode, 0, dir, buf, len);
  }
}

/**
 * Set log mode
 * @param logger IN logger instance
 * @param mode IN log mode
 */
void xauxi_logger_set_mode(xauxi_logger_t *logger, int mode) {
  logger->mode = mode;
}
/**
 * Get log mode
 * @param logger IN logger instance
 */
int xauxi_logger_get_mode(xauxi_logger_t *logger) {
  return logger->mode;
}

