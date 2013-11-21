------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
------------------------------------------------------------------------------

local _cookie = {}

------------------------------------------------------------------------------
-- Parse a cookie string and return a sorted cookie table
-- @param cookiestr IN received cookie string
-- @return sorted cookie table
------------------------------------------------------------------------------
function _cookie.parse(cookiestr)
  local cookies = {}
  string.gsub(cookiestr, "([%w%p]*) *= *([%w%p]) *,?", function(key, value)
    table.insert(cookies, { key = key, value = value })
  end)
  return cookies
end

return _cookie

