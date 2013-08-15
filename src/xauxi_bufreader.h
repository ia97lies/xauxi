/**
 * Copyright 2012 Christian Liesch
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
 * Interface of the xauxi buffered reader.
 */

#ifndef XAUXI_BUFREADER_H
#define XAUXI_BUFREADER_H

typedef struct xauxi_bufreader_s xauxi_bufreader_t;

/**
 * New xauxi_bufreader object 
 * @param pool IN pool
 * @param buf IN buffer to read
 * @param len IN buffer len
 * @return an apr status
 */
xauxi_bufreader_t *xauxi_bufreader_new(apr_pool_t * pool, const char *buf, 
                                       apr_size_t len); 
/**
 * read line from file 
 * @param self IN xauxi_bufreader object
 * @param line OUT read line
 * @return an apr status
 */
apr_status_t xauxi_bufreader_read_line(xauxi_bufreader_t * self, char **line);

/**
 * Read specifed block
 *
 * @param self IN xauxi_bufreader object
 * @param block IN a block to fill up
 * @param length INOUT length of block, on return length of filled bytes
 *
 * @return APR_SUCCESS else APR error
 */
apr_status_t xauxi_bufreader_read_block(xauxi_bufreader_t * self, char *block,
                                        apr_size_t *length);

#endif
