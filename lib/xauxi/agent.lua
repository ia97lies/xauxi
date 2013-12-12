local Class = require("luanode.class")
local EventEmitter = require "luanode.event_emitter"
local net = require("luanode.net")

local _M = {
	_NAME = "xauxi.http",
	_PACKAGE = "xauxi."
}

-- Make LuaNode 'public' modules available as globals.

local Paired = Class.InheritsFrom(EventEmitter)
_M.Paired = Paired

Paired.defaultMaxSockets = 1
function Paired:__init (options)
  local new = Class.construct(Paired)

  new.options = options or {}
  new.sockets = {}
  new.maxSockets = new.options.maxSockets or Paired.defaultMaxSockets

  return new
end

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

function Paired:getHostPort(hostname, req)
    local host = nil
    local port = nil
    if hostname == nil then
        req.emit("error", "Backend host string is nil", 0)
    elseif type(hostname) == "string" then
      host, port = parseHostName(hostname)
    elseif type(hostname) == "table" then
      if #hostname > 0 then
        host, port = parseHostName(hostname[1])
      else
        req.emit("error", "Wrong formated backend host", 0)
      end
    else
      req.emit("error", "Wrong backend host type "..type(hostname), 0)
    end
    return host, port
end

function Paired:setFrontendRequest(req)
  self.frontendRequest = req
end

function Paired:setSecureContext(context)
  self.secureContext = context 
end

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
      -- don;t close frontend here as we have
      -- a better control in engine it self
    end)
  else
    proxy_req:onSocket(backend)
  end
end

return _M
