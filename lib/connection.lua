-- module connection
local connection = {}

function connection.new()
  local connection = { 
    buf = {},

    ---------------------------------------------------------------------------
    -- check if connection contains data
    -- @param self IN self pointer
    -- @return true if empty else false
    ---------------------------------------------------------------------------
    isEmpty = function(self)
      if #self.buf == 0 then 
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
      local reqSize = size
      local curSize = 0
      return function()
        if curSize < reqSize then
          v = self.buf[1]
          if v ~= nil then
            if curSize + string.len(v) > reqSize then
              diff = reqSize - curSize
              _v = string.sub(v, 1, diff)
              self.buf[1] = string.sub(v, diff+1)
              v = _v
            else
              table.remove(self.buf, 1)
            end
            curSize = curSize + string.len(v)
          end
          if curSize == reqSize then
            return v, true
          else
            return v, false
          end
        end
        return nil, true
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
              table.remove(self.buf, 1)
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
          if string.len(data) > 0 then
            table.insert(self.buf, data)
          end
          return nil 
        end
        table.remove(self.buf, 1)
      end
    end
  }
  return connection
end

return connection
