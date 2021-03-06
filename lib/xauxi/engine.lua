------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Xauxi Engine
------------------------------------------------------------------------------

local version = "0.1.0"
local http = require("luanode.http")
local url = require("luanode.url")
local fs = require("luanode.fs")
local log_file = require("logging.file")
local crypto = require ("luanode.crypto")

local agent = require("xauxi/agent")
local ha = require("xauxi/ha")

local fileMap = {}

requestId = 1
connectionId = 1

local xauxiEngine = {}
local defaultAgent = agent.Paired()
local defaultSelector = ha.Off()

------------------------------------------------------------------------------
-- If no filter is set take the ident handler
-- @param event IN 'begin', 'data', 'end'
-- @req IN luanode request object
-- @res IN luanode response object
-- @chunk IN a chunk of data
-- @return received chunk of data, doing nothing with it 
------------------------------------------------------------------------------
function identHandle(event, req, res, chunk)
  return chunk
end

------------------------------------------------------------------------------
-- store status code of the backend in the request for logging purpose
-- @req IN luanode request object
-- @res IN luanode response object
------------------------------------------------------------------------------
function overwriteWriteHead(req, res)
  local _writeHead = res.writeHead
  return function(res, statusCode, ...)
    _writeHead(res, statusCode, ...)
    req.statusCode = statusCode
  end
end

------------------------------------------------------------------------------
-- To write the transaction into transaction log we hook us into the finish
-- method of the repsonse to frontend
-- @req IN luanode request object
-- @res IN luanode response object
------------------------------------------------------------------------------
function overwriteFinish(req, res, transferLog)
  local _finish = res.finish
  return function(res, data, encoding)
    _finish(res, data, encoding)
    req.time.finish = os.clock()
    transferLog.log(req.vhost.transferLog.logger, req, res)
  end
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
end

------------------------------------------------------------------------------
-- Pass request to a backend
-- @param config IN configuration array following entries
--   server, req, res, host, port, timeout, handleInput, handleOutput
------------------------------------------------------------------------------
function _pass(server, req, res, config)
  req:on('error', function (self, msg, code)
    xauxiEngine.trace('error', req, msg, code)
  end)

  req:on('close', function()
    xauxiEngine.trace('debug', req, "Frontend connection closed")
  end)

  if config.chain == nil or config.chain.input == nil then
    handleInput = identHandle
  else
    handleInput = config.chain.input
  end
  local chunk = handleInput('begin', req, res, null)

  local agent = config.agent or defaultAgent
  agent:setFrontendRequest(req)
  if config.ssl then
    agent:setSecureContext(crypto.createContext(config.ssl))
  else
    agent:setSecureContext(nil)
  end
  if config.selector ~= nil then
    agent:setHostSelector(config.selector)
  else
    agent:setHostSelector(defaultSelector)
  end
  local host, port = agent:getHostPort(config.host)

  local proxy_req = http.request({
    host = host,
    port = port,
    method = req.method,
    path = url.parse(req.url).pathname,
    headers = req.headers,
    agent = agent
  }, function(self, proxy_res)
    if config.chain == nil or config.chain.output == nil then
      handleOutput = identHandle
    else
      handleOutput = config.chain.output
    end
    local chunk = handleOutput('begin', req, proxy_res, null)
    req.time.backend = os.clock()
    res:writeHead(proxy_res.statusCode, proxy_res.headers)
    req.statusCode = proxy_res.statusCode
    if chunk then
      res:write(chunk)
    end

    proxy_res:on("data", function(self, chunk)
      chunk = handleOutput('data', req, proxy_res, chunk)
      if chunk then
        res:write(chunk)
      end
    end)

    proxy_res:on("end", function()
      chunk = handleOutput('end', req, proxy_res, chunk)
      if chunk then
        res:write(chunk)
      end
      res:finish()
    end)
  end)

  proxy_req:on('error', function (self, msg, code)
    -- TODO: mark this sucker bad or maybe do it also with some listener for everyhost
    xauxiEngine.trace('error', req, msg, code)
    xauxiEngine.sendServerError(req, res)
  end)

  proxy_req:on('close', function ()
    xauxiEngine.trace('debug', req, "Backend connection closed")
  end)

  if config.timeout ~= nil then
    proxy_req:setTimeout(config.timeout)
  end
  if chunk then
    proxy_req:write(chunk)
  end

  req:on('data', function (self, chunk)
    chunk = handleInput('data', req, res, chunk)
    if chunk then
      proxy_req:write(chunk) 
    end
  end)

  req:on('end', function ()
    req.time.frontend = os.clock()
    chunk = handleInput('end', req, res, null)
    if chunk then
      proxy_req:write(chunk) 
    end
    proxy_req:finish()
  end)
end

function xauxiEngine.pass(config)
  local server = config[1]
  local req = config[2]
  local res = config[3]
  _pass(server, req, res, config)
end

------------------------------------------------------------------------------
-- run the proxy
-- @parm server IN hashmap
--   @entry port IN port to listen to
--   @entry map IN map function to schedule requests
------------------------------------------------------------------------------
function xauxiEngine.run(config)
  errorLogger = log_file(config.serverRoot.."/logs/"..config.errorLog.file)
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
        vhost.transferLog.logger = log_file(config.serverRoot.."/logs/"..vhost.transferLog.file)
        req.vhost.errorLog = config.errorLog
        req.vhost.errorLog.logger = errorLogger
        req.time = { }
        req.time.start = os.clock()
        req.uniqueId = string.format("%d-%d-%d", i, connectionId, requestId)
        requestId = requestId + 1

        -- instrument the res methods to measure time and write access log
        -- even if the functions are called directly :)
        res.finish = overwriteFinish(req, res, vhost.transferLog);
        res.writeHead = overwriteWriteHead(req, res);

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
      if config.backlog == nil then
        proxy._backlog = 1024
      else
        proxy._backlog = backlog
      end
      proxy:listen(vhost.port, vhost.host)

    end
  end

  errorLogger:info('Proxy up and running')

  -- TODO: Should add error handling and terminate on error.

  process:loop()
end

return xauxiEngine

