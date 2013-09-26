-- module connection
local connection = {}

function connection.new()
  local connection = { 
    buf = {},
    size = -1,
    curSize = -1,

    ---------------------------------------------------------------------------
    -- Depreciated
    ---------------------------------------------------------------------------
    getBuf = function(self)
      return table.concat(self.buf)
    end,

    ---------------------------------------------------------------------------
    -- check if connection contains data
    -- @param self IN self pointer
    -- @return true if empty else false
    ---------------------------------------------------------------------------
    isEmpty = function(self)
      for i in pairs(self.buf) do
        return true 
      end
      return false
    end,

    ---------------------------------------------------------------------------
    -- push data to connection
    -- @param self IN self pointer
    -- @param data IN data to push
    ---------------------------------------------------------------------------
    pushData = function(self, data)
      table.insert(self.buf, data)
    end,

    ---------------------------------------------------------------------------
    -- get data block by size
    -- @param self IN self pointer
    -- @param size IN number of bytes to get
    -- @param block IN if true it returns nil if not enough data
    -- @return data if enough is available else nil
    ---------------------------------------------------------------------------
    getData = function(self, size)
      if self.size == -1 then
        self.size = size
        self.curSize = 0
      end
      local data = ""
      if self.curSize < self.size then
        v = self.buf[1]
        if v ~= nil then
          self.curSize = self.curSize + string.len(v)
          table.remove(self.buf, 1)
        end
        return v, self:isEmpty() 
      else
        self.size = -1
        return nil, self:isEmpty()
      end
      -- skipped and removed later
      while true do
        v = self.buf[1]
        if v then
          data = data..v
          if string.len(data) > size then
            local _data = string.sub(data, 1, size)
            local rest = string.sub(data, size+1)
            self.buf[1] = rest
            data = _data
            break
          end
        else
          break
        end
        v = table.remove(self.buf, 1)
      end
      if string.len(data) > 0 then
        if string.len(data) ~= size then
          table.insert(self.buf, data)
          return nil, self:isEmpty()
        else
          return data, self:isEmpty()
        end
      else
        return nil, self:isEmpty()
      end
    end,

    ---------------------------------------------------------------------------
    -- get line
    -- @param self IN self pointer
    -- @return data if there is a line terminated by \r\n else nil
    ---------------------------------------------------------------------------
    getLine = function(self)
      local data = ""
      while true do
        v = self.buf[1]
        if v then
          data = data..v
          s, e = string.find(data, "\r\n") 
          if s then
            if e == string.len(data) then
              v = table.remove(self.buf, 1)
            else
              self.buf[1] = string.sub(data, e + 1)
            end
            if s == 1 then
              return ""
            else
              return string.sub(data, 1, s - 1)
            end
          end
        else
          return nil 
        end
        v = table.remove(self.buf, 1)
      end
    end
  }
  return connection
end

return connection
