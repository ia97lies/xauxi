------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Cookie Parser
------------------------------------------------------------------------------

local _cookie = {}

------------------------------------------------------------------------------
-- Parse a cookie string and return a sorted cookie table
-- @param cookiestr IN received cookie string
-- @return sorted cookie table
------------------------------------------------------------------------------
function _cookie.parse(cookiestr)
  local cookies = {}
  string.gsub(cookiestr, "([^, ]*) *= *([^, ]*) *,?", function(key, rawValue)
    value = string.gsub(rawValue, "\"", "")
    cookies[key] = value
  end)
  return cookies
end

return _cookie

