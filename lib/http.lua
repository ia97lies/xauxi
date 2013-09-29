-- module http
request = require("request")
conn = require("connection")
local http = {}

connections = {}

-- public
function http.location(uri, loc)
  return string.sub(uri, 1, string.len(loc)) == loc
end

function http.stream(connection, data, nextFilter)
  if data ~= nil then
    local r
    local c = connections[connection]
    if c ~= nil then
      if c.request == nil then
        c.request = request.new()
      end
    else
      c = conn.new()
      r = request.new()
      c.request = r
      r.connection = c
      connections[connection] = c 
    end
    r = c.request
    r:
    -- todo handle multiple request or incomplete requests
    -- If header state does return not finish wait for more
    -- If body state return false wait for more
    -- Else handle next request, or buffer (wait for request completion maybe)
  else
    connections[connection] = nil
  end
end

return http

