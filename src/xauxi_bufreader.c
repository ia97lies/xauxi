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
 * Implementation of the xauxi buffered reader.
 */

/************************************************************************
 * Includes
 ***********************************************************************/
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
#include <apr.h>
#include <apr_strings.h>
#include <apr_file_io.h>
#include <apr_buckets.h>

#include "xauxi_defines.h" \
#include "xauxi_bufreader.h"


/************************************************************************
 * Definitions 
 ***********************************************************************/

struct xauxi_bufreader_s {
  apr_status_t status;
  apr_pool_t *pool;
  apr_size_t i;
  apr_size_t len;
  apr_bucket_alloc_t *alloc;
  apr_bucket_brigade *line;
  char *buf;
};


/************************************************************************
 * Forward declaration 
 ***********************************************************************/

/**
 * Fill up buffer with data from file 
 * @param bufreader IN xauxi_bufreader object
 * @return an apr status
 */
static apr_status_t _bufreader_fill(xauxi_bufreader_t * bufreader); 

/**
 * Check fp and read file
 * @param bufreader IN xauxi_bufreader object
 * @return apr status
 */
static apr_status_t _file_read(xauxi_bufreader_t *bufreader);

/**
 * Create a plain bufreader
 * @param pool IN pool
 * @return bufreader
 */
static xauxi_bufreader_t *_bufreader_new(apr_pool_t * pool); 

/************************************************************************
 * Public
 ***********************************************************************/

xauxi_bufreader_t *xauxi_bufreader_buf_new(apr_pool_t * pool, const char *buf, 
                                       apr_size_t len) { 
  xauxi_bufreader_t *bufreader = _bufreader_new(pool);
  bufreader->buf = apr_pcalloc(bufreader->pool, len);
  memcpy(bufreader->buf, buf, len);
  bufreader->len = len;
  return bufreader;
}

apr_status_t xauxi_bufreader_read_line(xauxi_bufreader_t * bufreader, char **line) {
  char c;
  apr_size_t i;
  apr_status_t status = APR_SUCCESS;
  int leave_loop = 0;

  *line = NULL;

  i = 0;
  c = 0;
  apr_brigade_cleanup(bufreader->line);
  while (leave_loop == 0 && (status = _file_eof(bufreader)) != APR_EOF) {    
    if (bufreader->i >= bufreader->len) {
      if ((status = _bufreader_fill(bufreader)) != APR_SUCCESS) {
        break;
      }
    }

    if (bufreader->i < bufreader->len) {
      c = bufreader->buf[bufreader->i];
      if (c == '\r' || c == '\n') {
	c='\0';
	leave_loop=1;
      }
      apr_brigade_putc(bufreader->line, NULL, NULL, c);
      bufreader->i++;
      i++;

    }
  }

  apr_brigade_putc(bufreader->line, NULL, NULL, '\0');
  apr_brigade_pflatten(bufreader->line, line, &i, bufreader->pool);

  while (**line == ' ' || **line == '\t') {
    ++*line;
  }

  return status;
}

apr_status_t xauxi_bufreader_read_block(xauxi_bufreader_t * bufreader, char *block,
                                      apr_size_t *length) {
  apr_status_t status;
  int i;
  int len = *length;

  status = APR_SUCCESS;

  (*length) = 0;

  i = 0;
  while (i < len) {
    if (bufreader->i >= bufreader->len) {
      if ((status = _bufreader_fill(bufreader)) != APR_SUCCESS) {
        break;
      }
    }

    block[i] = bufreader->buf[bufreader->i];
    ++i;
    ++bufreader->i;
  }

  /* on eof we like to get the bytes recvieved so far */
  while (i < len && bufreader->i < bufreader->len) {
    block[i] = bufreader->buf[bufreader->i];
    ++i;
    ++bufreader->i;
  }

  *length = i;

  return status;
}

/************************************************************************
 * Private
 ***********************************************************************/

static xauxi_bufreader_t *_bufreader_new(apr_pool_t * pool) {
  apr_allocator_t *allocator;
  xauxi_bufreader_t *bufreader;
  apr_pool_t *bpool;

  apr_pool_create(&bpool, pool);
  bufreader = apr_pcalloc(bpool, sizeof(xauxi_bufreader_t));
  bufreader->pool = bpool;
  bufreader->alloc = apr_bucket_alloc_create(bufreader->pool);
  bufreader->line = apr_brigade_create(bufreader->pool, bufreader->alloc);
  allocator = apr_pool_allocator_get(bufreader->pool);
  apr_allocator_max_free_set(allocator, 1024*1024);
  bufreader->status = APR_SUCCESS;

  return bufreader;
}

static apr_status_t _bufreader_fill(xauxi_bufreader_t * bufreader) {
  bufreader->i = 0;

  if (bufreader->status != APR_SUCCESS) {
    return bufreader->status;
  }

  bufreader->status = _file_read(bufreader);
  return bufreader->status;
}

static apr_status_t _file_read(xauxi_bufreader_t *bufreader) {
  if (bufreader->fp) {
    return apr_file_read(bufreader->fp, bufreader->buf, &bufreader->len);
  }
  else {
    bufreader->len = 0;
    bufreader->i = 0;
    return APR_EOF;
  }
}

static apr_status_t _file_eof(xauxi_bufreader_t *bufreader) {
  if (bufreader->fp) {
    return apr_file_eof(bufreader->fp);
  }
  else if (bufreader->i >= bufreader->len) {
    return APR_EOF;
  }
  else {
    return APR_SUCCESS;
  }
}

