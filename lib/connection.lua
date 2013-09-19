-- module connection
local connection = {}

function connection.new()
  local connection = { 
    buf = {},
    getBuf = function(self)
      return table.concat(self.buf)
    end 
  }
  return connection
end

return connection
