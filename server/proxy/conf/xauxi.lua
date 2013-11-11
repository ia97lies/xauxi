package.path = package.path..";/home/cli/workspace/xauxi/lib/?.lua;./?.lua"
xauxi = require "XauxiEngine"

function rewriteRequestBodyToFoo(req, res, chunk)
  if res == nil then
    req.headers["content-length"] = nil
  elseif chunk == nil then
    return "foo"
  else
    return nil
  end
end

server = {
  port = 8080,

  map = function(self, req, res)
    if xauxi.location(req, "/test/1") then
      xauxi.pass(self, req, res, "localhost", 9090)
    elseif xauxi.location(req, "/test/rewrite") then
      xauxi.pass(self, req, res, "localhost", 9090, rewriteRequestBodyToFoo)
    else
      xauxi.notFound(self, req, res)
    end
  end
}

xauxi.run(
  server
)

