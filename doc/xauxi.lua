http = require "http"

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(frontend, data)
      http.frontend(frontend, data, function(req, data)
        if http.location(req.uri, "/proxy") then
          http.backend(req, "localhost:8090", function() end)
        else
          req:say(404, "Not Found")
        end
      end)
    end)
  go()
end
