### Welcome to xauxi.
xauxi is a event driven reverse proxy. The configuration is a Lua script. In the configuration you have full access to the connection/request/response including the body data. It is easy to write own plugins to manipulate request, response and data. As http is just a plugin written in Lua it is possible to handle any kind of protocol by writing particular plugins. As it is event driven the plugins must keep track of their state while receiving the data. Plugins after the http plugin will only get the body data and a request record. It is possible to write plugins either in C/C++ or Lua.

Xau xi is vietnamese and stands for ugly. The idea is to solve standard use cases with a simple configuration but also be able to handle realy nasty situations. For example handle test clients or monitors different to normal user. It would be even possible to inject a configuration by authentication service, for example user specific settings bound to the users role.

Last but not least the fun factor and learning Lua is the main task here ;)

### Version
Alpha vesion. Just checkout the git repo or download the tar ball provided by github. Write your very own small configuration, take test/simple as a base.

### Features
* Simple response method
* Request routing with standard Lua if conditions 
* Keepalive request (but not able to handle Connection header)
* Concurrency

### How to build
```
./configure && make all
```
Binary can be found in the src directory.


### How to run tests 
You need httest (at least 2.4.8) installed. You can either get the tar ball from sourceforge and build it or if you are running ubuntu ```sudo apt-get install httest ```

#### Run all tests
```
make check
```

#### Run lua unit tests
Single lua tests
```
cd test; ./lua_unit <lua-file>
```

#### Run integration tests
All httest
```
cd test; ./run_httest.sh
```

Single httest
```
./src/xauxi --root test/simple --lib lib > xauxi.log &
cd test; ./run.sh <htt-file>
```

### How to start
```
xauxi --root <root-path> --lib <lib-paths>
```
*root-path* points to xauxi root directory. The root directory must contain a "conf" directory with the xauxi.lua configuration in it as well as a "run" directory for the pid file. Currently the log is written to stdout, you can redirect it to your log file.

```
<xauxi-root-dir>/
<xauxi-root-dir>/conf/xauxi.lua
<xauxi-root-dir>/run
```

*lib-paths* is a Lua path definition, where the xauxi Lua modules can be found. the Lua modules are in the lib directory of the tar ball.

Let's head and start xauxi in the tar ball, of course you need to ./configure && make first.
```
./src/xauxi --root test/simple --lib lib
```

### Sample configuration
A sample configuration could look as follow
```
http = require "http"

-- Frist simple proxy configuration 
function global()
  listen("localhost:8080",
    function(connection, data)
      http.stream(connection, data, function(r, data)
        if http.location(r.uri, "/foo") then
          r:say(200, "hit 1 /foo location")
        elseif http.location(r.uri, "/bar") then
          r:say(200, "hit 1 /bar location")
        else
          r:say(404, "404 Not Found")
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


