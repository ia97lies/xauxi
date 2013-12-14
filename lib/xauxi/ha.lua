------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Xauxi High Availability
------------------------------------------------------------------------------

local Class = require("luanode.class")
local EventEmitter = require "luanode.event_emitter"

local _M = {
	_NAME = "xauxi.ha",
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
-- Single backend no high availability
------------------------------------------------------------------------------
local Off = Class.InheritsFrom(EventEmitter)
_M.Off = Off

------------------------------------------------------------------------------
-- init function
-- @param options IN not used so far
------------------------------------------------------------------------------
function Off:__init (options)
  local new = Class.construct(Off)

  new.options = options or {}

  return new
end

------------------------------------------------------------------------------
-- Parse hostname string and return host, port
-- @param request IN frontend request
-- @param hostname IN String 
-- @return host and port
------------------------------------------------------------------------------
function Off:getHostPort(request, hostname)
    local host = nil
    local port = nil
    if hostname == nil then
        self.emit("error", "Backend host string is nil", 0)
    elseif type(hostname) == "string" then
      host, port = parseHostName(hostname)
    else
      self.emit("error", "Wrong backend host type "..type(hostname), 0)
    end
    return host, port
end

------------------------------------------------------------------------------
-- Single backend no high availability
------------------------------------------------------------------------------
local Distributed = Class.InheritsFrom(EventEmitter)
_M.Distributed = Distributed

------------------------------------------------------------------------------
-- init function
-- @param options IN not used so far
------------------------------------------------------------------------------
function Distributed:__init (options)
  local new = Class.construct(Distributed)

  new.options = options or {}
  new.backend = {}
  new.backend.index = 0

  return new
end

------------------------------------------------------------------------------
-- Parse hostname string and return host, port
-- @param request IN frontend request
-- @param hostname IN String 
-- @return host and port
------------------------------------------------------------------------------
function Distributed:getHostPort(request, hostname)
  local host = nil
  local port = nil
  if hostname == nil then
      error("Host string is nil")
  elseif type(hostname) == "table" then
    -- try to figure out which one, have a look into session
    -- else take the next one
    if self.backend.index >= #hostname then
      self.backend.index = 1
    else
      self.backend.index = self.backend.index + 1
    end
    host, port = parseHostName(hostname[self.backend.index])
  else
      error("Host string is not an array")
  end
  return host, port
end

return _M

