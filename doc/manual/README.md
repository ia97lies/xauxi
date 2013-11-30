## Manual
### Introduction
Xauxi is a very lean reverse proxy. It base on Lua. Even the configuration is a Lua script, actually it is the main part of the proxy server. As the configuration is actually a script you also have the full power on request and repsonse objects. This can be very helpfull if you have to workaround nasty backends.
But also convention by configuration is well supported. Combining scripting with convetion over configuration gives you great power and help to handle any situation. No need to wait for a new release because a featur is missing any more, help your self.

### Minimal Configuration
The following xauxi configuration is a minimal set and can be used as a skeleton.

```lua
package.path = package.path..";/path/to/xauxi/?.lua;"
xauxi = require "xauxi.engine"

xauxi.run {
  serverRoot = ".",
  errorLog = {
    file = "error.log"
  },

  {
    host = "localhost",
    port = 8080,
    transferLog = { 
      file = "access.log", 
      log = function(logger, req, res)
        logger:info("%s %s", req.method, req.url)
      end 
    },

    map = function(server, req, res)
      xauxi.sendNotFound(req, res)
    end
  }
}
```
#### Global Part
* serverRoot: Server root, where config and run directory can be found
* errorLog: Error log specification
* errorLog.file: Error log filename

#### Listener Host Part
* host: Hostname or IP
* port: Portnumber
* transferLog: Transfer log specification
* transferLog.file: Transfer log filename
* transferLog.log: Logger function
* map: The function to map your requests to backends

### Mapping Request to backend
As you have full access to the request/response objects you can map your request not only based on request url but also on headers, parameters and session attributes. Actually name based virtual server can be done based on the host header, more later.

#### Mapping based on URL
There is a helper "xauxi.location" for mapping requests based on its requested URL 
```lua
    ...
    map = function(server, req, res)
      if xauxi.location(req, "/test/1") then
        ...
      elseif xauxi.location(req, "/test/rewrite/request") then
        ...
      else
        xauxi.sendNotFound(req, res)
      end
    end
```

#### Mapping based on Headers
Currently there is no helper fr mapping request on headers, but Lua offers enough tools to match headers on any wished pattern you can imagnize.
```lua
    ...
    map = function(server, req, res)
      if req.headers["user-agent"] == "special" then
        ...
      else
        xauxi.sendNotFound(req, res)
      end
    end
    ...
```

### Proxy Request
The heart of xauxi is the proxy command "xauxi.pass", where you can specify your backend target. This is the minimum setup.
```lua
        ...
        xauxi.pass {
          server, req, res, 
          host = "localhost", 
          port = 9090 
        }
        ...
```
server: Server context
req: Request from client
res: Response to client
host: Backend host name or IP
port: Backend portnumber


