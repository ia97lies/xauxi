http = require "http"

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      http.stream(connection, data, function(r, buf)
        if http.location(r.uri, "/foo") then
          print("hit 1 /foo location")
        elseif http.location(r.uri, "/bar") then
          print("hit 1 /bar location")
        else
          print("404 Not Found")
        end
      end)
    end)
  go()
end
