-- helpers
Request = { 
  url = "", 
  headers = {}, 
  state = "header", 
  buf = "",
  getLine = function(self)
    s, e = string.find(self.buf, "\r\n") 
    if s then
      print("found newline " .. s ..", " .. e)
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

function newRequest()
  return Request
end

connections = {}

function http(connection, data, nextFilter)
  if data ~= nil then
    if connections[connection] ~= nil then
      print("established connection")
    else
      print("new connection")
      connections[connection] = newRequest() 
    end
    r = connections[connection]
    if r.state == "header" then
      r.buf = r.buf .. data
      line = r:getLine()
      while line do
        print("line: " .. line)
        line = r:getLine()
      end
    end
    nextFilter()
  else
    print("close connection")
    connections[connection] = nil
  end
end

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      http(connection, data, function()
        print("next filter")
      end)
    end)
  go()
end
