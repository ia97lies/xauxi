http = require "http"

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(frontend, data)
      http.frontend(frontend, data, function(r, data)
        if http.location(r.uri, "/proxy") then
          connect("localhost:8090", frontend, function(backend)
            backend:write("foo bar\r\n\r\n")
            print("connected!")
          end)
        else
          r:say(404, "Not Found")
        end
      end)
    end)
  go()
end
