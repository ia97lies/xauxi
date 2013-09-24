-- module connection
local connection = {}

function connection.new()
  local connection = { 
    buf = {},
    getBuf = function(self)
      return table.concat(self.buf)
    end,
    pushData = function(self, data)
      table.insert(self.buf, data)
    end,
    getData = function(self, size)
      -- for _ in pairs(self.buf) do count = count + 1 end
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
              --else
              --self.buf = string.sub(self.buf, e + 1)
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
