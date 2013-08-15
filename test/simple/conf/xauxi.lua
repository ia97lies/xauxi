-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
  function()
    print("Got data");
  end)
  go()
end
