local http = require("luanode.http")
local url = require("luanode.url")

local PROXY_PORT = 8080
local BACKEND_PORT = 9090

local xauxiCore = {}

function identFilter(req, res, chunk)
  return chunk
end

function xauxiCore.location(req, location)
  uri = url.parse(req.url).pathname
  return string.sub(uri, 1, string.len(location)) == location
end

function xauxiCore.pass(self, req, res, host, port, inputFilterChain)
  local headers = { Connection = 'keep-alive',
                    Host = host..':'..port }
print("XXXXXXXXXXXXXXXXX", host, port, inputFilterChain)
  if inputFilterChain == nil then
    inputFilterChain = identFilter
  end
  local proxy_client = http.createClient(port, host)
  inputFilterChain(req, null, null)
  local proxy_req = proxy_client:request(req.method, url.parse(req.url).pathname, req.headers)

  req:addListener('data', function (self, chunk)
    chunk = inputFilterChain(req, res, chunk)
    if chunk then
      proxy_req:write(chunk) 
    end
  end)

  req:addListener('end', function ()
    chunk = inputFilterChain(req, res, null)
    if chunk then
      proxy_req:write(chunk) 
    end
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
end

function xauxiCore.run(server)
  local proxy = http.createServer(function (self, req, res)
    server.map(self, req, res)
  end):listen(server.port)

  console.log('Xauxi running at http://127.0.0.1:'..server.port)
  process:loop()
end
return xauxiCore

