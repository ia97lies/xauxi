------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Xauxi Agent
------------------------------------------------------------------------------

local Class = require("luanode.class")
local EventEmitter = require "luanode.event_emitter"
local net = require("luanode.net")

local _M = {
	_NAME = "xauxi.agent",
	_PACKAGE = "xauxi."
}

------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------
local function parseHostName(hostname)
  local host
  local port
  string.gsub(hostname, "(.*):(.*)", function(hostStr, portStr)
    host = hostStr
    if portStr then
      port = portStr
    else
      port = 80
    end
  end)
  return host, port
end

------------------------------------------------------------------------------
-- Paired agent pairs the frontend and backend connection. If one of them 
-- closes it's counterpart closes too. Usefull for NTLM for example.
------------------------------------------------------------------------------
local Paired = Class.InheritsFrom(EventEmitter)
_M.Paired = Paired

Paired.defaultMaxSockets = 1

------------------------------------------------------------------------------
-- init method to instantiate a new paired agent
-- @param options IN
-- @return new paired agent
------------------------------------------------------------------------------
function Paired:__init (options)
  local new = Class.construct(Paired)

  new.options = options or {}
  new.sockets = {}
  new.maxSockets = new.options.maxSockets or Paired.defaultMaxSockets

  return new
end

------------------------------------------------------------------------------
-- Implement against luanode inoffical interface. This is the minimum
-- requirement to work with luanode. This method lookup a backend connection
-- and sticks it to a the backend request object.
-- @param proxy_req IN request to backend
-- @param host IN host we want to have a connection
-- @param port IN port we want to have a connection
-- @param localAddress IN not needed here
------------------------------------------------------------------------------
function Paired:addRequest (proxy_req, host, port, localAddress)
  local sockets = self.sockets
  local frontend = self.frontendRequest.connection
  local backend = sockets[frontend]
  if backend == nil then
    backend = net.createConnection({
      port = port,
      host = host,
      localAddress = localAddress
    })
    
    backend.host = host
    backend.port = port
    backend:setEncoding("utf8")
    if self.secureContext ~= nil then
      backend:on("error", function(self, msg, code)
        proxy_req:emit("error", msg, code)
      end)
      backend:on("connect", function()
        backend:setSecure(self.secureContext);
      end)

      backend:on("secure", function()
        proxy_req:onSocket(backend)
      end)
    else
      proxy_req:onSocket(backend)
    end

    sockets[frontend] = backend
    -- stick on frontend connection and close to backend
    -- if frontend close.
    frontend:on('close', function(self, err)
      sockets[frontend] = nil
      backend:destroy()
    end)
    backend:on('close', function(self, err)
      sockets[frontend] = nil
      -- don;t close frontend here as we have a better control in engine it self
      -- else we can not send a 500 error to client
    end)
  else
    proxy_req:onSocket(backend)
  end
end

------------------------------------------------------------------------------
-- Add a host selector algorithme.
------------------------------------------------------------------------------
function Paired:setHostSelector(selector)
  self.selector = selector
end

------------------------------------------------------------------------------
-- Set the current frontend request, as luanode do know nothing about
-- @param req IN frontend request
------------------------------------------------------------------------------
function Paired:setFrontendRequest(req)
  self.frontendRequest = req
end

------------------------------------------------------------------------------
-- Set secure context if there is any.
-- @param context IN crypto context or nil
------------------------------------------------------------------------------
function Paired:setSecureContext(context)
  self.secureContext = context 
end

------------------------------------------------------------------------------
-- Get host and port depending of a hostname vaiable.
-- @param hostname IN can be one or more hosts with additional stuff
-- @return host and port or nil if nothing can be found
------------------------------------------------------------------------------
function Paired:getHostPort(hostname)
  local backend = self.sockets[self.frontendRequest.connection]
  if not backend then
    return self.selector:getHostPort(self.frontendRequest, hostname)
  else
    return backend.host, backend.port
  end
end

return _M

