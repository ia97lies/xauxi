-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      print("got data " .. data .. " from \"" .. tostring(connection) .. "\"")
    end)
  go()
end
