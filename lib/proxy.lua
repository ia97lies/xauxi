local http = require("luanode.http")
local url = require("luanode.url")
local headers = {Connection = 'keep-alive',
                 Host = 'localhost:9090' }

local PROXY_PORT = 8080
local BACKEND_PORT = 9090

local proxy_client = http.createClient(BACKEND_PORT, "localhost")
local proxy = http.createServer(function (self, req, res)
  local proxy_req = proxy_client:request(req.method, url.parse(req.url).pathname, req.headers)

  req:addListener('data', function (self, chunk)
    proxy_req:write(chunk) 
  end)

  req:addListener('end', function ()
    proxy_req:finish()
  end)

  proxy_req:addListener('response', function(self, proxy_res)
    res:writeHead(proxy_res.statusCode, proxy_res.headers)

    proxy_res:addListener("data", function(self, chunk)
      res:write(chunk)
    end)

    proxy_res:addListener("end", function()
      res:finish()
    end)

  end)
end):listen(PROXY_PORT)

process:loop()
