------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Remote Debugger
------------------------------------------------------------------------------

local info = require("xauxi.info")
local http = require("luanode.http")
local url = require("luanode.url")
local querystring = require("luanode.querystring")
local fs = require("luanode.fs")

local _debugger = {}

------------------------------------------------------------------------------
-- Get variable value and scope
------------------------------------------------------------------------------
function _getVariable(variable)
  local value
  local found = false
  local level = 2
  for i = 1, math.huge do
    
  end
end

------------------------------------------------------------------------------
-- Listen to a port
------------------------------------------------------------------------------
function _debugger.listen(port)
  local server = http.createServer(function (server, req, res)
    local pathname = url.parse(req.url).pathname
    local query = querystring.parse(req.url)
    if pathname == "/version" then
      res:writeHead(200, {["Content-Type"] = "text/json"})
      res:write("{ \"message\" = \"Version "..info.version.."\" }")
      res:finish()
    elseif pathname == "/value" then
      local variable = query["variable"]
      if variable ~= nil then

      else
        res:writeHead(500, {["Content-Type"] = "text/json"})
        res:write("{ \"message\" : \"Variable not specified\" }")
        res:finish()
      end
      res:writeHead(200, {["Content-Type"] = "text/json"})
      res:write("{ \"message\" = \"Version "..info.version.."\" }")
      res:finish()
    else
      res:writeHead(404, {["Content-Type"] = "text/json"})
      res:write("{ \"message\" : \"Command not found\" }")
      res:finish()
    end
  end):listen(port)
end

return _debugger

