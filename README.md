### Welcome to xauxi.
xauxi is a event driven reverse proxy based on lua. The configuration is in fact a lua script. You have full access to the connection/request/response including the possible body data. As http is just a lua filter which is feed by the connections incomming data it is possible to handle any kind of protocol.

### Sample configuration
A sample configuration could look as follow
```
http = require "http"

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080",
    function(connection, data)
      http.filter(connection, data, function(r, buf)
        if http.location(r.uri, "/foo") then
          say(200, "hit 1 /foo location")
        elseif http.location(r.uri, "/bar") then
          say(200, "hit 1 /bar location")
        else
          say(404, "404 Not Found")
        end
      end)
    end)
  go()
end
```

### Authors and Contributors
Project is started 2013 by Christian Liesch (@ia97lies)

### Licence
Apache 2 licence

