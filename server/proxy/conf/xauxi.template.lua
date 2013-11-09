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

function mapper(self, req, res)
  if xauxi.location(req, "/test/1") then
    xauxi.pass(self, req, res)
  elseif xauxi.location(req, "/test/rewrite") then
    xauxi.pass(self, req, res, rewriteRequestBodyToFoo)
  else
    xauxi.notFound(self, req, res)
  end
end

xauxi.run(
  mapper
)

