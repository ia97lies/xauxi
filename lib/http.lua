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
    if connections[connection] ~= nil then
      print("established connection")
    else
      print("new connection")
      local c = conn.new()
      local r = request.new()
      c.request = r
      r.connection = c
      connections[connection] = c 
    end
    c = connections[connection]
    if c.buf ~= nil then
      data = data..c.buf
    end
    r = c.request
    if r.state == "header" then
      print("state header")
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
          if r:bodyFilter(r.buf, nextFilter) then
            c.request = nil
            print("request done")
          end
          break
        end
      end
    else
      print("state body")
      if r:bodyFilter(data, nextFilter) then
        c.request = nil
        print("request done")
      end
    end
  else
    print("close connection")
    connections[connection] = nil
  end
end

return http

