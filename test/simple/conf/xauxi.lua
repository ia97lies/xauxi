-- Frist simple proxy configuration 
function global()
  listen("http://localhost:8080", 
  function()
    print("Got a connection on 8080");
  end)
end
