-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      print("got data " .. data)
    end)
  go()
end
