-- name based example
http = require "http"

function global()
  listen("localhost:8080", 
    function(frontend, data)
      http.frontend(frontend, data, function(req, data)
        if req.headers["Host"].value == "www.bla.fasel" then
          if http.location(req.uri, "/my/backend") then
            http.backend(req, "localhost:8090", function() end)
          else
            req:say(404, "Not Found")
          end
        else
          req:say(404, "Not Found")
        end
      end)
    end)
  go()
end
