-- helpers
Request = { 
  url = "", 
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
