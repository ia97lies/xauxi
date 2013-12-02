------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Xauxi Route
------------------------------------------------------------------------------

local url = require("luanode.url")

local _route = {}

------------------------------------------------------------------------------
-- location check
-- @param req IN LuaNode request
-- @param location IN location to match requests path
-- @return true if match else false
------------------------------------------------------------------------------
function _route.location(req, location)
  pathname = url.parse(req.url).pathname
  return string.sub(pathname, 1, string.len(location)) == location
end

------------------------------------------------------------------------------
------------------------------------------------------------------------------
function _route.host(req, host)
  if req.headers["host"] ~= nil then
    if type(host) == "table" then
    else
      if string.find(req.headers["host"], host) ~= nil then
        return true
      end
    end
  end
  return false
end

return _route
