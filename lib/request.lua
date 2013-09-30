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

function streamSize(self, len, nextPlugin)
  if self.getNext == nil then
    self.getNext = self.connection:getData(len)
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

function readChunk(self, nextPlugin)
  if self.chunkLen == 0 then
    local line = self.connection:getLine()
    if line then
      return true
    end
  else
    done = streamSize(self, self.chunkLen, nextPlugin)
    if done then
      self.chunked.stateFunc = chunkedLength
      return self.chunked.stateFunc(self, nextPlugin)
    end
  end
  return false
end

function chunkedLength(self, nextPlugin)
  local line = self.connection:getLine()
  while line and string.len(line) == 0 do
    line = self.connection:getLine()
  end
  if line then
    self.chunkLen = tonumber(line, 16)
    self.chunked.stateFunc = readChunk
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
    headers = headerTableNew(),

    ---------------------------------------------------------------------------
    -- read request headers and set state to body if done
    -- @param self IN self pointer
    ---------------------------------------------------------------------------
    readHeader = function(self)
      line = self.connection:getLine()
      while line do
        if string.len(line) > 0 then
          if self.theRequest == nil then
            self.theRequest = line
            self.method, self.uri, self.version = string.match(line, "(%a+)%s([%w%p]+)%s%a+%p([%d%p]+)")
          else
            name, value = string.match(line, "([-.%a]+):%s([%w%p%s]+)")
            self.headers[name] = value
          end
          line = self.connection:getLine()
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
      return streamSize(self, tonumber(len), nextPlugin)
    end,

    chunkedEncodingBody = function(self, nextPlugin)
      if self.chunked == nil then
        self.chunked = {}
        self.chunked.stateFunc = chunkedLength
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
      end
    end
  }
  return request
end


return request 
