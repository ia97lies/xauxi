------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Xauxi Backend Selection
------------------------------------------------------------------------------

local http = require("luanode.http")

local _backend = {}
local connections = {}

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
-- Connect to one single host
-- @param req IN request to lookup backend connection
-- @param hostname IN host:port
-- @return backend client
------------------------------------------------------------------------------
function _backend.single(req, hostname)
  local backend = connections[req.connection]  
  if backend == nil then
    local host = nil
    local port = nil
    if hostname == nil then
        error("Host string is nil")
    elseif type(hostname) == "string" then
      host, port = parseHostName(hostname)
    elseif type(hostname) == "table" then
      if #hostname > 0 then
        host, port = parseHostName(hostname[1])
      else
        error("Wrong formated host")
      end
    else
      error("Wrong host type "..type(hostname))
    end
    backend = http.createClient(port, host)
    connections[req.connection] = backend 
  end

  return backend
end

------------------------------------------------------------------------------
-- Distribute to a bunch of backends, hold backend host name in session if 
-- there
-- @param req IN request to lookup backend connection
-- @param hostname IN host:port
-- @return backend client
------------------------------------------------------------------------------
function _backend.distribute(req, hostname)
  local backend = connections[req.connection]  
  if backend == nil then
    local host = nil
    local port = nil
    if hostname == nil then
        error("Host string is nil")
    elseif type(hostname) == "table" then
      -- try to figure out which one, have a look into session
      -- else take the next one
      if hostname.index == nil then
        hostname.index == 1
      elseif hostname.index > #hostname then
      else
        hostname.index = hostname.index + 1
      end
      host, port = parseHostName(hostname[hostname.index])
    else
        error("Host string is not an array")
    end
    backend = http.createClient(port, host)
    connections[req.connection] = backend 
  end
end

------------------------------------------------------------------------------
-- Remove backend connection bound to given request
-- @param req IN request to lookup backend connection
------------------------------------------------------------------------------
function _backend.del(req)
  connections[req.connection] = nil
end

return _backend

