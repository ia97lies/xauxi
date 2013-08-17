-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(request)
      print "got request"
      connect(request, "localhost:8081", 10000)
    end)
  go()
end
