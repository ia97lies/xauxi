require "config"
xauxi = require "xauxi.engine"
http = require('luanode.http')
log_file = require("logging.file")
errorLogger = log_file("content_error.log")

http.createServer(function(server, req, res)
  server:addListener('error', function (self, msg, code)
    errorLogger:error("%d %s(%d)", req.uniqueId, msg, code)
  end)
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
    xauxi.sendNotFound(server, req, res)
  end
end):listen(9091)

console.log('Server running at http://127.0.0.1:9091/')

process:loop()

