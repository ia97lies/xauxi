xauxi = require "XauxiEngine"
http = require('luanode.http')

http.createServer(function(self, request, response)
  if xauxi.location(req, "/hello") then
    response:writeHead(200, {["Content-Type"] = "text/plain"})
    response:finish("Hello World")
  else
    xauxi.sendNotFound(res)
  end
end):listen(9091)

console.log('Server running at http://127.0.0.1:9091/')

process:loop()

