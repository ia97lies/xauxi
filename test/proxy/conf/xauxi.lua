http = require "http"

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      http.stream(connection, data, function(r, data)
        if http.location(r.uri, "/proxy") then
          http.pass(r, data, "localhost:8090")
        else
          r:say(404, "Not Found")
        end
      end)
    end)
  go()
end
