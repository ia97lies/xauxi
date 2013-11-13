------------------------------------------------------------------------------
-- Copyright 2006 Christian Liesch
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

local http = require("luanode.http")
local url = require("luanode.url")
local log_file = require("logging.file")

local frontendBackendMap = {}

local xauxiCore = {}

function identFilter(event, req, res, chunk)
  return chunk
end

------------------------------------------------------------------------------
-- location check
-- @param req IN LuaNode request
-- @param location IN location to match requests path
-- @return true if match else false
------------------------------------------------------------------------------
function xauxiCore.location(req, location)
  uri = url.parse(req.url).pathname
  return string.sub(uri, 1, string.len(location)) == location
end

------------------------------------------------------------------------------
-- Send fix server error message
-- @param res IN LuaNode response
-- @note: If want custome error page, write a filter for it.
------------------------------------------------------------------------------
function xauxiCore.sendServerError(res)
  res:writeHead(500, {["Content-Type"] = "text/html"})
  res:write("<html><body><h2>Internal Server Error</h2></body></html>")
  res:finish()
end

------------------------------------------------------------------------------
-- Send fix not found message 
-- @param res IN LuaNode response
-- @note: If want custome not found page, write a filter for it.
------------------------------------------------------------------------------
function xauxiCore.sendNotFound(res)
  res:writeHead(404, {["Content-Type"] = "text/html"})
  res:write("<html><body><h2>Not Found</h2></body></html>")
  res:finish()
end

------------------------------------------------------------------------------
-- Pass request to a backend
-- @param self IN LuaNode server
-- @param req IN LuaNode request
-- @param res IN LuaNode response
-- @param host IN host name
-- @param port IN port name
-- @param inputFilterChain IN hook for input filters
-- TODO: better use one single table with host, port, ssl stuff, ....
------------------------------------------------------------------------------
function xauxiCore.pass(self, req, res, host, port, inputFilterChain)
  local proxy_client = frontendBackendMap[req.connection]  
  if proxy_client == nil then
    proxy_client = http.createClient(port, host)
    frontendBackendMap[req.connection] = proxy_client
  end
  if inputFilterChain == nil then
    inputFilterChain = identFilter
  end
  inputFilterChain('begin', req, res, null)
  local proxy_req = proxy_client:request(req.method, url.parse(req.url).pathname, req.headers)

  proxy_client:addListener('error', function (self, msg, code)
    console.error("Backend: %s:%d", msg, code)
    xauxiCore.sendServerError(res)
  end)

  req:addListener('data', function (self, chunk)
    chunk = inputFilterChain('data', req, res, chunk)
    if chunk then
      proxy_req:write(chunk) 
    end
  end)

  req:addListener('end', function ()
    chunk = inputFilterChain('end', req, res, null)
    if chunk then
      proxy_req:write(chunk) 
    end
    proxy_req:finish()
  end)

  proxy_req:addListener('response', function(self, proxy_res)
    res:writeHead(proxy_res.statusCode, proxy_res.headers)

    proxy_res:addListener("data", function(self, chunk)
      res:write(chunk)
    end)

    proxy_res:addListener("end", function()
      res:finish()
    end)
  end)
end

------------------------------------------------------------------------------
-- run the proxy
-- @parm server IN hashmap
--   @entry port IN port to listen to
--   @entry map IN map function to schedule requests
------------------------------------------------------------------------------
requestId = 0
function xauxiCore.run(server)
  local logger = log_file(server.transferLog.file)
  local proxy = http.createServer(function (self, req, res)
    req.startT = os.clock()
    req.uniqueId = requestId
    requestId = requestId + 1
    server.map(self, req, res)
    server.transferLog.log(logger, self, req, res)
  end):listen(server.port)

  -- TODO: Should add error handling and terminate on error.

  console.log('Xauxi running at http://127.0.0.1:'..server.port)
  process:loop()
end
return xauxiCore

