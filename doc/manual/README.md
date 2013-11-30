## Manual
### Introduction
Xauxi is a very lean reverse proxy. It base on Lua. Even the configuration is a Lua script, actually it is the main part of the proxy server. As the configuration is actually a script you also have the full power on request and repsonse objects. This can be very helpfull if you have to workaround nasty backends.
But also convention by configuration is well supported. Combining scripting with convetion over configuration gives you great power and help to handle any situation. No need to wait for a new release because a featur is missing any more, help your self.

### Minimal Configuration
The following xauxi configuration is a minimal set and can be used as a skeleton.

```
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
serverRoot: Server root, where config and run directory can be found
errorLog: Error log specification
errorLog.file: Error log filename

#### Listener Host Part
host: hostname or IP
port: portnumber
transferLog: Transfer log specification
transferLog.file: transfer log filename
transferLog.log: Logger function
map: The function to map your requests to backends

### Mapping Request to backend
As you have full access to the request/response objects you can map your request not only based on request url but also on headers, parameters and session attributes. Actually name based virtual server can be done based on the host header, more later.
#### Mapping base on URL
There is a helper "xauxi.location" for mapping requests based on its requested URL 
```
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

