-- module connection
local connection = {}

function connection.new()
  local connection = { 
    buf = {},
    getBuf = function(self)
      return table.concat(self.buf)
    end,
    isEmpty = function(self)
      count = 0
      for _ in pairs(self.buf) do count = count + 1 end
    end
  }
  return connection
end

return connection
