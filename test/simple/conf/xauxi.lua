-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(hook, data)
      conn = get_connection(hook)
      print("got data " .. data .. " from \"" .. tostring(conn) .. "\"")
      --print("got data from connection \"" .. connection.tostring() .. "\" : " .. data)
      --print("got data from connection " .. data)
    end)
  go()
end
