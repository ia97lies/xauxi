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
      local tot = 0
      local data = ""
      repeat
        v = table.remove(self.buf, 1)
        if v then
          tot = tot + string.len(v)
          data = data..v
        else
          break
        end
      until tot >= size 
      if string.len(data) > size then
        local _data = string.sub(data, 1, size)
        local rest = string.sub(data, size+1)
        table.insert(self.buf, rest)
        return _data
      elseif string.len(data) > 0 then
        return data
      else
        return nil
      end
    end
  }
  return connection
end

return connection
