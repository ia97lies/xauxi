------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Xauxi Engine
------------------------------------------------------------------------------

local version = "0.0.1"
local http = require("luanode.http")
local url = require("luanode.url")
local fs = require("luanode.fs")
local log_file = require("logging.file")
local crypto = require ("luanode.crypto")

local fileMap = {}
local frontendBackendMap = {}

requestId = 1
connectionId = 1

local xauxiEngine = {}

function identHandle(event, req, res, chunk)
  return chunk
end

------------------------------------------------------------------------------
-- To have fast access cache all read files mostly this will be certs/keys
-- @param name IN filename
-- @param vhost IN vhost stuff for error logging
-- @param ftype IN 'ascii' or 'binary'
-- @return file content as a string
------------------------------------------------------------------------------
function lookupFile(name, vhost, ftype)
  local content = fileMap[name]
  if content == nil then
    local ok, msg = pcall(function()
      content = fs.readFileSync(name, ftype)
    end)
    if ok then
      fileMap[name] = content
    else
      vhost.errorLog.logger:error("%d Can not open file: %s", vhost.id, msg)
    end
  end
  return content
end

------------------------------------------------------------------------------
-- Get/create a backend connection
-- @param req IN request to lookup backend connection
-- @param host IN host to connect to
-- @param port IN port to connect to
-- Note: Should move that to a plugin
------------------------------------------------------------------------------
function xauxiEngine.getBackend(req, host, port)
  local backend = frontendBackendMap[req.connection]  
  if backend == nil then
    backend = http.createClient(port, host)
    frontendBackendMap[req.connection] = backend 
  end

  return backend
end

------------------------------------------------------------------------------
-- Remove backend connection bound to given request
-- @param req IN request to lookup backend connection
-- Note: Should move that to a plugin
------------------------------------------------------------------------------
function xauxiEngine.delBackend(req)
  frontendBackendMap[req.connection] = nil
end

------------------------------------------------------------------------------
-- trace function for easy usage
-- @param level IN error, info, debug
-- @param req IN request from frontend
-- @param msg IN error message from luanode
-- @param code IN unix error code
------------------------------------------------------------------------------
function xauxiEngine.trace(level, req, msg, code)
  if level == 'error' then
    req.vhost.errorLog.logger:error("%s %s(%d)", req.uniqueId, msg, code)
  elseif level == 'info' then
    req.vhost.errorLog.logger:info("%s %s", req.uniqueId, msg)
  elseif level == 'debug' then
    req.vhost.errorLog.logger:debug("%s %s", req.uniqueId, msg)
  else
    req.vhost.errorLog.logger:error("%s unsupported trace level %s", req.uniqueId, level)
  end
end

------------------------------------------------------------------------------
-- location check
-- @param req IN LuaNode request
-- @param location IN location to match requests path
-- @return true if match else false
------------------------------------------------------------------------------
function xauxiEngine.location(req, location)
  uri = url.parse(req.url).pathname
  return string.sub(uri, 1, string.len(location)) == location
end

------------------------------------------------------------------------------
-- Send fix server error message
-- @param req IN LuaNode request
-- @param res IN LuaNode response
-- @note: If want custome error page, write a filter for it.
------------------------------------------------------------------------------
function xauxiEngine.sendServerError(req, res)
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
function xauxiEngine.sendNotFound(req, res)
  res:writeHead(404, {["Content-Type"] = "text/html", ["Connection"] = "close"})
  res:write("<html><body><h2>Not Found</h2></body></html>")
  res:finish()
  req.statusCode = 404
  req.time.finish = os.clock()
  req.vhost.transferLog.log(req.vhost.transferLog.logger, req, res)
end

------------------------------------------------------------------------------
-- Pass request to a backend
-- @param config IN configuration array following entries
--   server, req, res, host, port, timeout, handleInput, handleOutput
------------------------------------------------------------------------------
function xauxiEngine.pass(config)
  server = config[1]
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
    xauxiEngine.trace('error', req, msg, code)
    xauxiEngine.delBackend(req)
  end)

  req.connection:addListener('close', function()
    xauxiEngine.trace('debug', req, "Frontend connection closed")
    xauxiEngine.delBackend(req)
  end)

  proxy_client:addListener('connect', function()
    if  config.ssl ~= nil then
      if config.ssl.ca ~= nil then
        local caPem = lookupFile(config.ssl.ca, req.vhost, 'ascii')
      end
      if config.ssl.cert ~= nil then
        local certPem = lookupFile(config.ssl.cert, req.vhost, 'ascii')
      end
      if config.ssl.key ~= nil then
        local keyPem = lookupFile(config.ssl.key, req.vhost, 'ascii')
      end
      local context = crypto.createContext{key = keyPem, cert = certPem, ca = caPem}
      proxy_client:setSecure(context)
    end
  end)

  proxy_client:addListener('error', function (self, msg, code)
    xauxiEngine.trace('error', req, msg, code)
    xauxiEngine.sendServerError(req, res)
    xauxiEngine.delBackend(req)
  end)

  proxy_client:addListener('close', function ()
    xauxiEngine.trace('debug', req, "Backend connection closed")
    xauxiEngine.delBackend(req)
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
function xauxiEngine.run(config)
  errorLogger = log_file(config.serverRoot.."/"..config.errorLog.file)
  errorLogger:info('Start xauxi proxy '..version)
  if config.init then
    config.init(errorLogger)
  end
  
  for i, vhost in ipairs(config) do
    if type(i) == "number" then
      errorLogger:info('Proxy listen at http://'..vhost.host..':'..vhost.port)
      vhost.id = i
      local proxy = http.createServer(function (server, req, res)
        req.vhost = vhost 
        req.server = server
        req.vhost.transferLog.logger = log_file(config.serverRoot.."/"..vhost.transferLog.file)
        req.vhost.errorLog = config.errorLog
        req.vhost.errorLog.logger = errorLogger
        req.time = { }
        req.time.start = os.clock()
        req.requestId = requestId
        req.uniqueId = string.format("%d-%d", i, requestId)
        requestId = requestId + 1
        vhost.map(server, req, res)
      end)

      proxy.ssl = false
      if vhost.ssl ~= nil then
        if vhost.ssl.ca ~= nil then
          local caPem = lookupFile(vhost.ssl.ca, vhost, 'ascii')
        end
        local certPem = lookupFile(vhost.ssl.cert, vhost, 'ascii')
        local keyPem = lookupFile(vhost.ssl.key, vhost, 'ascii')
        local context = crypto.createContext{key = keyPem, cert = certPem, ca = caPem}
        proxy.ssl = true
        proxy:setSecure(context)
      end

      proxy:listen(vhost.port)

    end
  end

  errorLogger:info('Proxy up and running')

  -- TODO: Should add error handling and terminate on error.

  process:loop()
end
return xauxiEngine

