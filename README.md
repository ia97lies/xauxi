## Welcome to xauxi.
xauxi is a event driven reverse proxy. The configuration is a Lua script where you have full access to the connection/request/response including the body data. It is easy to write own plugins to manipulate request, response and data. It is possible to write plugins either in Lua or C/C++.

Xau xi is vietnamese and stands for ugly. The idea is to solve standard use cases with a simple configuration but also be able to handle nasty situations.

Xauxi is currently based on LuaNode a very fun and greate project and seems to have a better performance than node.js or luvit.

Feedback is highly recommended.

### Version
0.1.0 Beta

Xauxi is currently under heavy development don't use it in a productive enviroment yet as the configuration can change. 

### Documentation
* [Manual](https://github.com/ia97lies/xauxi/blob/master/doc/manual/README.md)

### Getting Started
#### Prerequisit
All example and checked in configs expect a $HOME/workspace so the first thing is do
```bash
cd
mkdir workspace
cd workspace
```

Then checkout xauxi
```bash
git clone git@github.com:ia97lies/xauxi.git
```
Or download a release from github and extract it 
```bash
cd xauxi
```

#### Ubuntu
On ubuntu system run the follwing script in the xauxi folder
```bash
./ubuntu.sh
```

#### Red Hat
On a red hat system run the follwing script in the xauxi folder
```bash
./redhat.sh
```

#### Others
All others try to run ./generic.sh and resolve conflicts by hand

#### Build
```bash
make all
```

#### Testing
You need a [httest](https://sourceforge.net/projects/htt/) to run all tests.
```bash
make test
```

### Hello World
Paste the following configuration in a file hello.lua in your xauxi home dir.
```lua
package.path = package.path..";./build/?.lua;"
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
      if xauxi.location(req, "/hello/world") then
        res:writeHead(200, {["Content-Type"] = "text/plain"})
        res:finish("Hello World")
      else
        xauxi.sendNotFound(req, res)
      end
    end
  }
}
```

Call 
```bash
./build/bin/xauxi hello.lua
```

Open your browser and type localhost:8080/hello/world in your navigation bar.

### Examples
For more sophisticated examples have a look at the example directory and/or the server/proxy/conf/xauxi.lua which is used to for testing.

### Future Plan
 - Full fledge SSL support for front and backend connection
 - Request router for more convenience
 - A REST debugger interface to tackle configuration problems
 - Gzip plugin
 - Redis integration to store session
 - Bullet proof error handling - currently the poxy terminates on error, is ok for development but not for production settup
 - Websockets tunneling
 - Authentication plugin

### Authors and Contributors
Project started 2013 by Christian Liesch (@ia97lies)

## Acknowledgements #
I'd like to acknowledge the work of the following people or group:

 - Ignacio Burgueno, for [LuaNode](http://ignacio.github.com/LuaNode)
 - Danilo Tuler and Thiago Ponte, for http://neopallium.github.com/lualogging/
 - Paul Kulchenko, for serpent


### Licence
MIT Licencse

