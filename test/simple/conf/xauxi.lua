-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection)
      print "got data"
    end)
  go()
end
