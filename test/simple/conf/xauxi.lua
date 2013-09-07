-- helpers
Request = { url = "", headers = {}, state = "header",
            getState = function(self) return self.state end,
            setState = function(self, state) self.state = state end 
          }

function newRequest()
  local i = 0;
  return function()
    i = i +1
    return i
  end
end

connections = {}

function http(connection, data, nextFilter)
  if connections[connection] ~= nil then
    print("connection found")
  else
    connections[connection] = newRequest() 
    print("connection not found")
  end
  print("komisch "..connection:tostring().." "..connections[connection]())
  nextFilter()
end

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      http(connection, data, function()
        print("next filter")
      end)
    end)
  go()
end
