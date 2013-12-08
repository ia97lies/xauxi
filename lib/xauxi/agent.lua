local Class = require("luanode.class")
local EventEmitter = require "luanode.event_emitter"
local net = require("luanode.net")

local _M = {
	_NAME = "xauxi.http",
	_PACKAGE = "xauxi."
}

-- Make LuaNode 'public' modules available as globals.

local Agent = Class.InheritsFrom(EventEmitter)
_M.Agent = Agent

Agent.defaultMaxSockets = 1
function Agent:__init (options)
  local new = Class.construct(Agent)

  new.options = options or {}
  new.sockets = {}
  new.maxSockets = new.options.maxSockets or Agent.defaultMaxSockets
end

function Agent:addRequest (req, host, port, localAddress)
  conn = net.createConnection({
    port = port,
    host = host,
    localAddress = localAddress
  })
  req:onSocket(conn)
end

return _M
