-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      filter.http(connection, data, function(request, data)
        print("got data " .. data .. " from \"" .. tostring(connection) .. "\"")
      end)
    end)
  go()
end
