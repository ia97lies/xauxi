http = require "http"

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080", 
    function(connection, data)
      http.frontend(connection, data, function(r, data)
        if http.location(r.uri, "/proxy") then
          connect("localhost:8090", function(connection)
            print("connected!")
          end)
        else
          r:say(404, "Not Found")
        end
      end)
    end)
  go()
end
