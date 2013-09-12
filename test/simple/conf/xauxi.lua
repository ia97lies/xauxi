-- helpers
Request = { 
  method = "",
  uri = "",
  version = "",
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

function headerTableNew()
  local headerTable = {}
  meta = {}
  function meta.__newindex(t, k, v)
    local entry = { key = k, val = v }
    if type(k) == "string" then
      k = string.lower(k)
    end
    rawset(t, k, entry)
  end

  function meta.__index(t, k)
    if type(k) == "string" then
      k = string.lower(k)
    end
    e = rawget(t, k)
    return e
  end

  setmetatable(headerTable, meta)
  return headerTable
end

connections = {}

function http(connection, data, nextFilter)
  if data ~= nil then
    if connections[connection] ~= nil then
      print("established connection")
    else
      print("new connection")
      local r = Request
      r.headers = headerTableNew()
      connections[connection] = r 
    end
    r = connections[connection]
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
            -- TODO: overwrite table method of r.headers to be able to lookup case insensitiv
            --       without storing the name lower case, want them untouched
            r.headers[name] = value
            print(r.headers[name].key, r.headers[name].val)
          end
          line = r:getLine()
        else
          r.state = "body"
          if r.headers["Content-Length"] then
            print("Content-Length body")
          elseif r.headers["Transfer-Encoding"].val:lower() == "chunked" then
            print("Chunked Encoded body")
          end
          nextFilter(r, r.buf)
          break
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
