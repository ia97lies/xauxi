-- module http
request = require("request")
conn = require("connection")
local http = {}

connections = {}

-- public
function http.location(uri, loc)
  return string.sub(uri, 1, string.len(loc)) == loc
end

function http.filter(connection, data, nextFilter)
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
    if r.state == "header" then
      r.buf = r.buf .. data
      line = r:getLine()
      while line do
        if string.len(line) > 0 then
          if r.theRequest == nil then
            r.theRequest = line
            r.method, r.uri, r.version = string.match(line, "(%a+)%s([%w%p]+)%s%a+%p([%d%p]+)")
          else
            name, value = string.match(line, "([-.%a]+):%s([%w%p%s]+)")
            r.headers[name] = value
          end
          line = r:getLine()
        else
          r.state = "body"
          r:bodyFilter(r.buf, nextFilter)
          break
        end
      end
    else
      r:bodyFilter(data, nextFilter)
    end
  else
    connections[connection] = nil
  end
end

return http

