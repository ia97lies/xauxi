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

function readBlockFilter(self, data, len, nextFilter)
  -- print("cl "..len.." cur "..self.curRecvd.." dlen "..string.len(data))
  if self.curRecvd == len+0 then
    -- print("cur == cl")
    table.insert(self.connection.buf, data)
  elseif self.curRecvd + string.len(data) <= len+0 then
    -- print("cur + dlen < cl")
    self.curRecvd = self.curRecvd + string.len(data)
    nextFilter(self, data)
  else
    -- print("cur + dlen > cl")
    -- cut data and stuff it back to connection
    diff = len - r.curRecvd
    table.insert(self.connection.buf, string.sub(data, diff+1))
    rest = string.sub(data, 1, diff)
    -- print("rest"..rest)
    self.curRecvd = len+0 
    nextFilter(self, rest)
  end
end

function readChunkFilter(self, data, nextFilter)
  if self.chunked.state == "header" then
    self.buf = self.buf..data
    line = self:getLine()
    if line and string.len(line) > 0 then
      self.chunked.len = "0x"..line
      if self.chunked.len+0 > 0 then
        self.chunked.state = "body"
        data = self.buf
        self.buf = ""
        readBlockFilter(self, data, self.chunked.len, nextFilter)
        if self.curRecvd == self.chunked.len+0 then
          self.chunked.state = "header"
        end
      else
        self.chunked.state = "done"
        if string.len(self.buf) > 0 then
          table.insert(self.connection.buf, self.buf)
          self.buf = ""
        end
      end
    end
  else
    readBlockFilter(self, data, self.chunked.len, nextFilter)
    if self.curRecvd == self.chunked.len+0 then
      self.chunked.state = "header"
    end
  end
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
      -- print("Content-Length body")
      local len = self.headers["Content-Length"].val
      readBlockFilter(self, data, len, nextFilter)
    end,

    chunkedEncodingFilter = function(self, data, nextFilter) 
      while true do
        readChunkFilter(self, data, nextFilter)
        if self.chunked.state ~= "done" then
          data = self.connection:getBuf()
          self.connection.buf = {} 
          if self.connection:isEmpty() then
            break
          end
        else
          break
        end
      end
      -- loop over connection buf table and call readChunkFilter, as long as not done
    end,

    bodyFilter = function(self, data, nextFilter)
      if self.headers["Content-Length"] then
        self:contentLengthFilter(data, nextFilter)
      elseif self.headers["Transfer-Encoding"] and
             self.headers["Transfer-Encoding"].val:lower() == "chunked" then
        self.state = "body.chunkheader"
        self:chunkedEncodingFilter(data, nextFilter)
      end
    end
  }
  return request
end


return request 