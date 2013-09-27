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

function readChunk(self, nextPlugin)
  if self.chunkLen == 0 then
    local line = self.connection:getLine()
    if line then
      return true
    end
  end
  return false
end

function chunkedLength(self, nextPlugin)
  local line = self.connection:getLine()
  while string.len(line) == 0 do
    line = self.connection:getLine()
  end
  if line then
    self.chunkLen = line+0
    self.stateFunc = readChunk
    return self.stateFunc(self, nextPlugin)
  end
  return false
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
    chunked = { state = "header", len = 0, curRecvd = 0 },

    ---------------------------------------------------------------------------
    -- read request headers and set state to body if done
    -- @param self IN self pointer
    ---------------------------------------------------------------------------
    readHeader = function(self)
      line = self.connection:getLine()
      while line do
        if string.len(line) > 0 then
          if r.theRequest == nil then
            r.theRequest = line
            r.method, r.uri, r.version = string.match(line, "(%a+)%s([%w%p]+)%s%a+%p([%d%p]+)")
          else
            name, value = string.match(line, "([-.%a]+):%s([%w%p%s]+)")
            r.headers[name] = value
          end
          line = self.connection:getLine()
        else
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
      if self.getNext == nil then
        local len = self.headers["Content-Length"].val
        self.getNext = self.connection:getData(len+0)
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
    end,

    chunkedEncodingBody = function(self, nextPlugin)
      if self.stateFunc == nil then
        self.stateFunc = chunkedLength
      end
      return self.stateFunc(self, nextPlugin);
    end
  }
  return request
end


return request 
