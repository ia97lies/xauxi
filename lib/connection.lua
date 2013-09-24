-- module connection
local connection = {}

function connection.new()
  local connection = { 
    buf = {},

    ---------------------------------------------------------------------------
    -- Depreciated
    ---------------------------------------------------------------------------
    getBuf = function(self)
      return table.concat(self.buf)
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
    -- @return data if enough is available else nil
    ---------------------------------------------------------------------------
    getData = function(self, size)
      local data = ""
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
          return nil
        else
          return data
        end
      else
        return nil
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
