local http = require('luanode.http')

http.createServer(function(self, request, response)
  response:writeHead(200, {["Content-Type"] = "text/plain"})
  response:finish("Hello World")
end):listen(9091)

console.log('Server running at http://127.0.0.1:9091/')

process:loop()
