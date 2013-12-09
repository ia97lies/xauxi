local Class = require("luanode.class")
local EventEmitter = require "luanode.event_emitter"
local net = require("luanode.net")

local _M = {
	_NAME = "xauxi.http",
	_PACKAGE = "xauxi."
}

-- Make LuaNode 'public' modules available as globals.

local Single = Class.InheritsFrom(EventEmitter)
_M.Single = Single

Single.defaultMaxSockets = 1
function Single:__init (options)
  local new = Class.construct(Single)

  new.options = options or {}
  new.sockets = {}
  new.maxSockets = new.options.maxSockets or Single.defaultMaxSockets

  return new
end

function Single:setFrontendRequest(req)
  self.frontendRequest = req
end

function Single:addRequest (req, host, port, localAddress)
  local sockets = self.sockets
  local frontend = self.frontendRequest.connection
  local backend = sockets[frontend]
  if backend == nil then
    backend = net.createConnection({
      port = port,
      host = host,
      localAddress = localAddress
    })
    sockets[frontend] = backend
    -- stick on frontend connection and close to backend
    -- if frontend close.
    frontend:on('close', function(self, err)
      sockets[frontend] = nil
      backend:destroy()
    end)
    backend:on('close', function(self, err)
      sockets[frontend] = nil
      frontend:destroy()
    end)
  end
  req:onSocket(backend)
end

return _M
