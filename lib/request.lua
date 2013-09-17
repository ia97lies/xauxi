-- module request 
local request = {}

-- private
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

-- public
function request.new()
  local request = { 
    method = "",
    uri = "",
    version = "",
    state = "header", 
    buf = "",
    headers = headerTableNew(),
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
    end,
    contentLengthFilter = function(self, data, nextFilter)
      print("Content-Length body")
      len = self.headers["Content-Length"].val
      if self.curRecvd + string.len(data) > len+0 then
        -- cut data and stuff it back to connection
        diff = self.curRecvd + string.len(data) - len
        self.connection.buf = string.sub(data, diff + 1)
        data = string.sub(data, 1, diff)
        nextFilter(self, data)
      elseif self.curRecvd + string.len(data) < len+0 then
        self.curRecvd = self.curRecvd + string.len(data)
        nextFilter(self, data)
      else
        print("Request body read")
        nextFilter(self, data)
        return true
      end
      return false
    end,
    chunkedEncodingFilter = function(self, data, nextFilter) 
      print("Chunked Encoded body")
      return true
    end,
    bodyFilter = function(self, data, nextFilter)
      if self.headers["Content-Length"] then
        return self:contentLengthFilter(data, nextFilter)
      elseif self.headers["Transfer-Encoding"].val:lower() == "chunked" then
        return self:chunkedEncodingFilter(data, nextFilter)
      else
        return true
      end
    end
  }
  return request
end

return request 
