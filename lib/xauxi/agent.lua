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

  new:on("free", function(self, socket, host, port, localAddress)
  end)
  return new
end

function Single:setFrontendRequest(req)
  self.frontendRequest = req
end

function Single:addRequest (req, host, port, localAddress)
  local conn = self.sockets[self.frontendRequest.connection]
  if conn == nil then
    conn = net.createConnection({
      port = port,
      host = host,
      localAddress = localAddress
    })
    self.sockets[self.frontendRequest.connection] = conn
  end
  req:onSocket(conn)
end

return _M
