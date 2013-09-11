-- helpers
Request = { 
  method = "",
  uri = "",
  version = "",
  headers = {}, 
  state = "header", 
  buf = "",
  getLine = function(self)
    s, e = string.find(self.buf, "\r\n") 
    if s then
      if s == 1 then
        line = ""
      else
        line = string.sub(self.buf, 1, s - 1)
      end
      if e == string.len(self.buf) then
        self.buf = ""
      else
        self.buf = string.sub(self.buf, e + 1)
      end
      return line
    else
      return nil
    end
  end
}

connections = {}

function http(connection, data, nextFilter)
  if data ~= nil then
    if connections[connection] ~= nil then
      print("established connection")
    else
      print("new connection")
      local r = Request
      connections[connection] = r 
    end
    r = connections[connection]
    if r.state == "header" then
      print("state header")
      r.buf = r.buf .. data
      line = r:getLine()
      while line do
        if r.theRequest == nil then
          r.theRequest = line
          r.method, r.uri, r.version = string.match(line, "(%a+)%s([%w%p]+)%s%a+%p([%d%p]+)")
        else
          name, value = string.match(line, "([-.%a]+):%s([%w%p%s]+)")
          -- TODO: overwrite table method of r.headers to be able to lookup case insensitiv
          --       without storing the name lower case, want them untouched
          print(name, value)
        end
        if string.len(line) == 0 then
          r.state = "body"
          nextFilter(r, r.buf)
          break
        else
          line = r:getLine()
        end
      end
    else
      print("state body")
      nextFilter(r, data)
    end
  else
    print("close connection")
    connections[connection] = nil
  end
end

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      http(connection, data, function(request, body)
        print("body: "..body)
      end)
    end)
  go()
end
