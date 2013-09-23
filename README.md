### Welcome to xauxi.
xauxi is a event driven reverse proxy based on Lua. The configuration is in fact a Lua script. You have full access to the connection/request/response including the possible body data. As http is just a Lua filter which is feed by the connections incomming data it is possible to handle any kind of protocol.

Xau xi is vietnamese and stands for ugly. The word itself sounds cute. That's xauxi, guly but cute. The idea is to solve 0815 use cases with a simple configuration but also be able to handle realy nasty situations. For example handle test clients or monitors different to normal user. It would be even possible to inject a configuration by authentication service, for example user specific settings bound to the users role.

### Version
Alpha vesion. Just checkout the git repo and explore the test cases and code. Or download the tar ball of the git repos.

### Features
Currently only plain TCP is supported. I will first get a feeling for the configuration and the code before introducing SSL.

### How to start
```
xauxi --root <root-path> --lib <lib-paths>
```
*root-path* points to xauxi root directory. In the root directory there must be a "conf" directory, where xaux.lua can be found.

*lib-paths* is a Lua path definition, where the xauxi Lua modules can be found. the Lua modules are in the lib directory of the tar ball.

Let's head and start xauxi in the tar ball, of course you need to ./configure && make first.
```
./src/xauxi --root test/simple --lib lib
```

Currently only read a http request is possible, but no response, I'm working on it...

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
Project started 2013 by Christian Liesch (@ia97lies)

### Licence
[Apache Licence Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)

