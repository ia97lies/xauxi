### Welcome to xauxi.
xauxi is a event driven reverse proxy. The configuration is a Lua script. In the configuration you have full access to the connection/request/response including the body data. It is easy to write own plugins to manipulate request, response and data. As http is just a plugin written in Lua it is possible to handle any kind of protocol by writing particular plugins. As it is event driven the plugins must keep track of their state while receiving the data. Plugins after the http plugin will only get the body data and a request record. It is possible to write plugins either in C/C++ or Lua.

Xau xi is vietnamese and stands for ugly. The idea is to solve standard use cases with a simple configuration but also be able to handle realy nasty situations. For example handle test clients or monitors different to normal user. It would be even possible to inject a configuration by authentication service, for example user specific settings bound to the users role.

Xauxi is currently based on LuaNode a very fun and greate project.

Last but not least the fun factor and learning Lua is the main task here ;)

### Version
alpha vesion. 

### Prerequisit Ubuntu
 - Install Lua and libraries
   - sudo apt-get install lua5.1 liblua5.1-0-dev luasocket-dev liblua5.1-json
 - Install OpenSSL
   - sudo apt-get install libssl-dev
 - Install Boost
   - sudo apt-get install libboost1.49-dev libboost-system1.49-dev
 - Get lualogging
   - sudo luarocks install lualogging

### Build Instructions
 - make workspace
 - cd workspace
 - git clone git://github.com/ignacio/LuaNode.git LuaNode
 - cd LuaNode/build
 - cmake ../
 - make
 
Now you have luanode in the LuaNode/build directory.

### Future Plan
 - Have one make/script to generate/build all needed stuff as much self contained as possible

### Authors and Contributors
Project started 2013 by Christian Liesch (@ia97lies)

### Licence
[Apache Licence Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)


