### Welcome to xauxi.
xauxi is a event driven reverse proxy. The configuration is a Lua script where you have full access to the connection/request/response including the body data. It is easy to write own plugins to manipulate request, response and data. It is possible to write plugins either in Lua or C/C++.

Xau xi is vietnamese and stands for ugly. The idea is to solve standard use cases with a simple configuration but also be able to handle nasty situations.

Xauxi is currently based on LuaNode a very fun and greate project and seems to be much more performant than node.js or luvit.

### Version
Beta

### Prerequisit Ubuntu
```
#Install Lua and libraries
sudo apt-get install lua5.1 liblua5.1-0-dev luasocket-dev
#Install OpenSSL
sudo apt-get install libssl-dev
#Install Boost
sudo apt-get install libboost1.49-dev libboost-system1.49-dev
#Get lualogging
sudo luarocks install lualogging
#For integration testing
sudo apt-get install httest
```

### Build Instructions
```
cd $HOME
make workspace
cd workspace
git clone git://github.com/ignacio/LuaNode.git LuaNode
cd LuaNode/build
cmake ../
make
git clone git@github.com:ia97lies/xauxi.git
make
```

luanode executable can be found $HOME/workspace/LuaNode/build/luanode

### Testing

```
apt-get install httest
```

Correct the paths in config/config.sh

Make/generate everything and start all tests
```
cd xauxi
make
```

Starting xauxi by hand
```
luanode server/proxy/conf/xauxi.lua
```

### Example
See example directory for sample configurations.

### Future Plan
Have one make/script to generate/build all needed stuff as much self contained as possible

### Authors and Contributors
Project started 2013 by Christian Liesch (@ia97lies)

## Acknowledgements #
I'd like to acknowledge the work of the following people or group:

 - Ignacio Burgueno, for [LuaNode](http://ignacio.github.com/LuaNode)
 - Danilo Tuler and Thiago Ponte, for http://neopallium.github.com/lualogging/
 - Paul Kulchenko, for serpent


### Licence
MIT Licencse

