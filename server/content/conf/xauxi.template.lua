xauxi = require "XauxiEngine"
http = require('luanode.http')

http.createServer(function(conn, req, res)
  if xauxi.location(req, "/test/luanode/hello") then
    res:writeHead(200, {["Content-Type"] = "text/plain"})
    res:finish("Hello World")
  elseif xauxi.location(req, "/test/luanode/huge") then
    res:writeHead(200, {["Content-Type"] = "text/plain"})
    res:write("begin")
    for i = 1,100 do
      res:write("..............................................................................................................")
    end
    res:finish("end")
  else
    xauxi.sendNotFound(conn, req, res)
  end
end):listen(9091)

console.log('Server running at http://127.0.0.1:9091/')

process:loop()

