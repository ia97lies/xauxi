### Welcome to xauxi.
xauxi is a event driven reverse proxy. The configuration is a Lua script where you have full access to the connection/request/response including the body data. It is easy to write own plugins to manipulate request, response and data. It is possible to write plugins either in Lua or C/C++.

Xau xi is vietnamese and stands for ugly. The idea is to solve standard use cases with a simple configuration but also be able to handle nasty situations.

Xauxi is currently based on LuaNode a very fun and greate project and seems to be much more performant than node.js or luvit.

### Version
Beta

### Make it work
#### Prerequisit
All example and checked in configs expect a $HOME/workspace so the first thing is do
```
cd
mkdir workspace
```

Then checkout xauxi
```
git clone git@github.com:ia97lies/xauxi.git
```

#### Ubuntu
On ubuntu run the follwing script
```
./ubuntu.sh
```
Now you have a running luanode in $HOME/workspace/xauxi/3rdparty/LuaNode/build directory

#### Others
Get a running LuaNode, see LuaNode on github how to build it

#### Testing
Make/generate everything and start all tests
```
cd xauxi
make
```

### Example
See example directory for sample configurations.
To start a example configuration you have first set the package path and include xauxi/lib there then you can start it

```
luanode examples/simple.xauxi
```

### Future Plan
 - Have one make/script to generate/build all needed stuff as much self contained as possible
 - Full fledge SSL support for front and backend connection
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

