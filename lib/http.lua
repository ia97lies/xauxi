-- module http
local http = {}

connections = {}

-- private
function requestNew()
  local request = { 
    method = "",
    uri = "",
    version = "",
    state = "header", 
    buf = "",
    curRecvd = 0,
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
  return request
end

function connectionNew()
  local connection = {}
  return connection
end

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

function contentLengthFilter(r, data, nextFilter)
  print("Content-Length body")
  len = r.headers["Content-Length"].val
  if r.curRecvd + string.len(data) > len+0 then
    -- cut data and stuff it back to connection
    diff = r.curRecvd + string.len(data) - len
    r.connection.buf = string.sub(data, diff + 1)
    data = string.sub(data, 1, diff)
    nextFilter(r, data)
  elseif r.curRecvd + string.len(data) < len+0 then
    r.curRecvd = r.curRecvd + string.len(data)
    nextFilter(r, data)
  else
    print("Request body read")
    nextFilter(r, data)
    return true
  end
  return false
end

function chunkedEncodingFilter(r, data, nextFilter)
  print("Chunked Encoded body")
  return true
end

function bodyFilter(r, data, nextFilter)
  if r.headers["Content-Length"] then
    return contentLengthFilter(r, data, nextFilter)
  elseif r.headers["Transfer-Encoding"].val:lower() == "chunked" then
    return chunkedEncodingFilter(r, data, nextFilter)
  else
    return true
  end
end

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
      local c = connectionNew()
      local r = requestNew()
      r.headers = headerTableNew()
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
          if bodyFilter(r, r.buf, nextFilter) then
            c.request = nil
            print("request done")
          end
          break
        end
      end
    else
      print("state body")
      if bodyFilter(r, data, nextFilter) then
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
