-- module http
request = require("request")
conn = require("connection")
local http = {}

connections = {}

-- private
function _readBody(r, nextPlugin)
  done = r:readBody(nextPlugin)
  if done then
    -- remove connection read handle
    -- after wrote response add connection read handle
    -- TODO: need connection remove read event
    --       need connection add read event
  end
  return done
end

-- public
function http.location(uri, loc)
  return string.sub(uri, 1, string.len(loc)) == loc
end

function http.stream(connection, data, nextPlugin)
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
    c:pushData(data)
    if r.http == nil then
      r.http = {}
      r.http.state = "headers"
    end
    if r.http.state == "headers" then
      done = r:readHeader(nextPlugin)
      if done then
        r.http.state = "body"
        done = _readBody(r, nextPlugin)
      end
      return done
    elseif r.http.state == "body" then
      done = _readBody(r, nextPlugin)
      return done
    end
  else
    connections[connection] = nil
  end
end

return http

