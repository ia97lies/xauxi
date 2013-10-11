http = require "http"

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      http.frontend(connection, data, function(r, data)
        if http.location(r.uri, "/foo") then
          r:say(200, "hit /foo location")
        elseif http.location(r.uri, "/bar") then
          r:say(200, "hit /bar location")
        else
          r:say(404, "Not Found")
        end
      end)
    end)
  go()
end
