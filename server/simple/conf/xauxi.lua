package.path = package.path..";/home/christian/workspace/xauxi/lib/?.lua;./?.lua"
xauxi = require "xauxiCore"


function rewriteRequestBodyToFoo(req, chunk)
  if chunk == nil then
    return "foo"
  else
    return null
  end
end

function identRequestBody(req, chunk)
  return chunk
end

function mapper(self, req, res)
  if xauxi.location(req, "/test/1") then
    xauxi.pass(self, req, res, rewriteRequestBodyToFoo)
  elseif xauxi.location(req, "/test/rewrite") then
    xauxi.pass(self, req, res, identRequestBody)
  end
end

xauxi.run(
  mapper
)

