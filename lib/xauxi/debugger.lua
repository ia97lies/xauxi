------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Remote Debugger
------------------------------------------------------------------------------

local info = require("xauxi.info")
local http = require("luanode.http")
local url = require("luanode.url")
local fs = require("luanode.fs")

local _debugger = {}

------------------------------------------------------------------------------
-- Listen to a port
------------------------------------------------------------------------------
function _debugger.listen(port)
  local server = http.createServer(function (server, req, res)
    local pathname = url.parse(req.url).pathname
    if pathname == "/version" then
      res:writeHead(200, {["Content-Type"] = "text/json"})
      res:write("{ version = "..info.version.." }")
      res:finish()
    else
      res:writeHead(404, {["Content-Type"] = "text/json"})
      res:write("{ notfound = 404 }")
      res:finish()
    end
  end):listen(port)
end

return _debugger

