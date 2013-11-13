xauxi = require "XauxiEngine"

function rewriteRequestBodyToFoo(event, req, res, chunk)
  if event == 'begin' then
    req.headers["content-length"] = nil
  elseif event == 'end' then
    return "foo"
  else
    return nil
  end
end

xauxi.run {
  host = "localhost",
  port = 8080,
  transferLog = { 
    file = "access.log", 
    log = function(logger, self, req, res)
      logger:info("%s %s %s %s %s", req.uniqueId, req.method, req.url, req.headers["user-agent"] or "<null>", req.headers["referer"] or "<null>")
    end 
  },

  map = function(self, req, res)
    if xauxi.location(req, "/test/1") then
      xauxi.pass(self, req, res, "localhost", 9090)
    elseif xauxi.location(req, "/test/rewrite") then
      xauxi.pass(self, req, res, "localhost", 9090, rewriteRequestBodyToFoo)
    else
      xauxi.sendNotFound(res)
    end
  end
}

