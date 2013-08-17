-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(request)
      print "got request"
      connect("localhot:8081")
    end)
  go()
end
