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

local version = "0.0.1"
local http = require("luanode.http")
local url = require("luanode.url")
local log_file = require("logging.file")

local frontendBackendMap = {}

requestId = 0
connctionId = 0

local xauxiCore = {}

function identHandle(event, req, res, chunk)
  return chunk
end

function xauxiCore.getBackend(req, host, port)
  local backend = frontendBackendMap[req.connection]  
  if backend == nil then
    backend = http.createClient(port, host)
    frontendBackendMap[req.connection] = backend 
  end

  return backend
end

function xauxiCore.delBackend(req)
  frontendBackendMap[req.connection] = nil
end

------------------------------------------------------------------------------
-- trace function for easy usage
-- @param level IN error, info, debug
-- @param req IN request from frontend
-- @param msg IN error message from luanode
-- @param code IN unix error code
------------------------------------------------------------------------------
function xauxiCore.trace(level, req, msg, code)
  if level == 'error' then
    req.vhost.errorLog.logger:error("%d %s(%d)", req.uniqueId, msg, code)
  elseif level == 'info' then
    req.vhost.errorLog.logger:info("%d %s", req.uniqueId, msg)
  elseif level == 'debug' then
    req.vhost.errorLog.logger:debug("%d %s", req.uniqueId, msg)
  else
    req.vhost.errorLog.logger:error("%d unsupported trace level %s", req.uniqueId, level)
  end
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
-- @param req IN LuaNode request
-- @param res IN LuaNode response
-- @note: If want custome error page, write a filter for it.
------------------------------------------------------------------------------
function xauxiCore.sendServerError(req, res)
  res:writeHead(500, {["Content-Type"] = "text/html", ["Connection"] = "close"})
  res:write("<html><body><h2>Internal Server Error</h2></body></html>")
  res:finish()
  req.statusCode = 500
  req.time.finish = os.clock()
  req.vhost.transferLog.log(req.vhost.transferLog.logger, req, res)
end

------------------------------------------------------------------------------
-- Send fix not found message 
-- @param req IN LuaNode request
-- @param res IN LuaNode response
-- @note: If want custome not found page, write a filter for it.
------------------------------------------------------------------------------
function xauxiCore.sendNotFound(req, res)
  res:writeHead(404, {["Content-Type"] = "text/html", ["Connection"] = "close"})
  res:write("<html><body><h2>Not Found</h2></body></html>")
  res:finish()
  req.statusCode = 404
  req.time.finish = os.clock()
  req.vhost.transferLog.log(req.vhost.transferLog.logger, req, res)
end

------------------------------------------------------------------------------
-- Pass request to a backend
-- @param server IN LuaNode server
-- @param req IN LuaNode request
-- @param res IN LuaNode response
-- @param config IN configuration array following entries
--   host, port, timeout, handleInput, handleOutput
-- TODO: better use one single table with host, port, ssl stuff, ....
------------------------------------------------------------------------------
function xauxiCore.pass(config)
  conn = config[1]
  req = config[2]
  res = config[3]
  local proxy_client = xauxi.getBackend(req, config.host, config.port)
  if config.handleInput == nil then
    handleInput = identHandle
  else
    handleInput = config.handleInput
  end
  local chunk = handleInput('begin', req, res, null)
  local proxy_req = proxy_client:request(req.method, url.parse(req.url).pathname, req.headers)
  if config.timeout ~= nil then
    proxy_req:setTimeout(config.timeout)
  end
  if chunk then
    proxy_req:write(chunk)
  end

  req.connection:addListener('error', function (self, msg, code)
    -- TODO: log in error log
    xauxiCore.trace('error', req, msg, code)
    xauxiCore.delBackend(req)
  end)

  req.connection:addListener('close', function()
    xauxiCore.trace('debug', req, "Frontend connection closed")
    xauxiCore.delBackend(req)
  end)

  proxy_client:addListener('error', function (self, msg, code)
    -- TODO: log in error log
    xauxiCore.trace('error', req, msg, code)
    xauxiCore.sendServerError(req, res)
    xauxiCore.delBackend(req)
  end)

  proxy_client:addListener('close', function ()
    -- TODO: log in error log
    xauxiCore.trace('debug', req, "Backend connection closed")
    xauxiCore.delBackend(req)
  end)

  req:addListener('data', function (self, chunk)
    chunk = handleInput('data', req, res, chunk)
    if chunk then
      proxy_req:write(chunk) 
    end
  end)

  req:addListener('end', function ()
    req.time.frontend = os.clock()
    chunk = handleInput('end', req, res, null)
    if chunk then
      proxy_req:write(chunk) 
    end
    proxy_req:finish()
  end)

  proxy_req:addListener('response', function(self, proxy_res)
    if config.handleOutput == nil then
      handleOutput = identHandle
    else
      handleOutput = config.handleOutput
    end
    local chunk = handleOutput('begin', req, proxy_res, null)
    req.time.backend = os.clock()
    res:writeHead(proxy_res.statusCode, proxy_res.headers)
    req.statusCode = proxy_res.statusCode
    if chunk then
      res:write(chunk)
    end

    proxy_res:addListener("data", function(self, chunk)
      chunk = handleOutput('data', req, proxy_res, chunk)
      if chunk then
        res:write(chunk)
      end
    end)

    proxy_res:addListener("end", function()
      chunk = handleOutput('end', req, proxy_res, chunk)
      if chunk then
        res:write(chunk)
      end
      res:finish()
      req.time.finish = os.clock()
      req.vhost.transferLog.log(req.vhost.transferLog.logger, req, res)
    end)
  end)
end

------------------------------------------------------------------------------
-- run the proxy
-- @parm server IN hashmap
--   @entry port IN port to listen to
--   @entry map IN map function to schedule requests
------------------------------------------------------------------------------
function xauxiCore.run(config)
  errorLogger = log_file(config.serverRoot.."/"..config.errorLog.file)
  errorLogger:info('Start xauxi proxy '..version)
  
  for i, vhost in ipairs(config) do
    if type(i) == "number" then
      errorLogger:info('Proxy listen at http://'..vhost.host..':'..vhost.port)
      local proxy = http.createServer(function (server, req, res)
        req.vhost = vhost 
        req.server = server
        req.vhost.transferLog.logger = log_file(config.serverRoot.."/"..vhost.transferLog.file)
        req.vhost.errorLog = config.errorLog
        req.vhost.errorLog.logger = errorLogger
        req.time = { }
        req.time.start = os.clock()
        req.uniqueId = requestId
        requestId = requestId + 1
        vhost.map(server, req, res)
      end):listen(vhost.port)

    end
  end

  errorLogger:info('Proxy up and running')

  -- TODO: Should add error handling and terminate on error.

  process:loop()
end
return xauxiCore

