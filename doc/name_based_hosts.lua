-- Frist simple proxy configuration 
function global()
  listen("localhost:8080",
    function(request)
      print("Got data")
      --name based server
      if (request.host == "www.bla.fasel") then
        if location("/foo") then
          -- filter chain and connect to target/file
          connect("localhot:8081")
        elseif location("/bar") then
          -- filter chain and connect to target/file
          connect("localhot:8081")
        else
          notfound()
        end
      else
        --if no name matched use this 
        if location("/the/rest") then
          say("hello")
        end
      end
    end)
  go()
end

