-- module request 
local request = {}
local status_codes = { 
  [200] = "OK",
  [404] = "Not Found",
  [500] = "Internal Server Error",
}


-- private
function _headerTableNew()
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

function _streamSize(self, len, nextPlugin)
  if self.getNext == nil then
    self.getNext = self.queue:getData(len)
  end
  buf, done = self.getNext()
  while buf ~= nil do
    nextPlugin(self, buf)
    buf, done = self.getNext()
  end
  if done then
    self.getNext = nil
  end
  return done
end

function _readChunk(self, nextPlugin)
  if self.chunkLen == 0 then
    local line = self.queue:getLine()
    if line then
      return true
    end
  else
    done = _streamSize(self, self.chunkLen, nextPlugin)
    if done then
      self.chunked.stateFunc = _chunkedLength
      return self.chunked.stateFunc(self, nextPlugin)
    end
  end
  return false
end

function _chunkedLength(self, nextPlugin)
  local line = self.queue:getLine()
  while line and string.len(line) == 0 do
    line = self.queue:getLine()
  end
  if line then
    self.chunkLen = tonumber(line, 16)
    self.chunked.stateFunc = _readChunk
    return self.chunked.stateFunc(self, nextPlugin)
  end
  return false
end

-- public
function request.new()
  local request = { 
    method = "",
    uri = "",
    version = "",
    headers = _headerTableNew(),

    ---------------------------------------------------------------------------
    -- read request headers and set state to body if done
    -- @param self IN self pointer
    ---------------------------------------------------------------------------
    readHeader = function(self)
      line = self.queue:getLine()
      while line do
          if string.len(line) > 0 then
            if self.theRequest == nil then
              self.theRequest = line
              self.method, self.uri, self.version = string.match(line, "(%a+)%s([%w%p]+)%s%a+%p([%d%p]+)")
            else
              name, value = string.match(line, "([-.%a]+):%s([%w%p%s]+)")
              self.headers[name] = value
            end
            line = self.queue:getLine()
          else
            if nextPlugin ~= nil then
              nextPlugin(self, "")
            end
            return true
          end
        end
        return false
      end,

      ---------------------------------------------------------------------------
      -- read read body and set state to "done" if all read 
      -- @param self IN self pointer
      -- @param nextPlugin IN call nextPlugin for body data chunks
      ---------------------------------------------------------------------------
      contentLengthBody = function(self, nextPlugin)
        local len = self.headers["Content-Length"].val
        return _streamSize(self, tonumber(len), nextPlugin)
      end,

    chunkedEncodingBody = function(self, nextPlugin)
      if self.chunked == nil then
        self.chunked = {}
        self.chunked.stateFunc = _chunkedLength
      end
      return self.chunked.stateFunc(self, nextPlugin);
    end,

    readBody = function(self, nextPlugin)
      if  self.headers["Content-Length"] then
        return self:contentLengthBody(nextPlugin)
      elseif self.headers["Transfer-Encoding"] then
        return self:chunkedEncodingBody(nextPlugin)
      else
        if nextPlugin ~= nil then
          nextPlugin(self, "")
        end
        return true
      end
    end,

    say = function(self, status, buffer)
      local data = "HTTP/1.1 "..status.." "..status_codes[status].."\r\nContent-Lengt: "..string.len(buffer).."\r\n\r\n"..buffer
      self.connection:batchWrite(data)
    end
  }
  return request
end


return request 
