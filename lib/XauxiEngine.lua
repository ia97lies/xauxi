local http = require("luanode.http")
local url = require("luanode.url")

local frontendBackendMap = {}

local xauxiCore = {}

function identFilter(req, res, chunk)
  return chunk
end

function xauxiCore.location(req, location)
  uri = url.parse(req.url).pathname
  return string.sub(uri, 1, string.len(location)) == location
end

function xauxiCore.sendServerError(res)
  res:writeHead(500, {["Content-Type"] = "text/html"})
  res:write("<html><body><h2>Internal Server Error</h2></body></html>")
  res:finish()
end

function xauxiCore.sendNotFound(res)
  res:writeHead(404, {["Content-Type"] = "text/html"})
  res:write("<html><body><h2>Not Found</h2></body></html>")
  res:finish()
end

function xauxiCore.pass(self, req, res, host, port, inputFilterChain)
  if inputFilterChain == nil then
    inputFilterChain = identFilter
  end
  -- bind client to req
  local proxy_client = http.createClient(port, host)
  inputFilterChain(req, null, null)
  local proxy_req = proxy_client:request(req.method, url.parse(req.url).pathname, req.headers)

  proxy_client:addListener('error', function (self, msg, code)
    console.error("Backend: %s:%d", msg, code)
    xauxiCore.sendServerError(res)
  end)

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

  -- TODO: Should add error handling and terminate on error.

  console.log('Xauxi running at http://127.0.0.1:'..server.port)
  process:loop()
end
return xauxiCore

