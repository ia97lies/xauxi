require "config"
xauxi = require "xauxi.engine"

local data = {}
for i = 1, 100 do
  table.insert(data, "..............................................................................................................")
end
huge = table.concat(data);

xauxi.run {
  serverRoot = XAUXI_HOME.."/server/content",
  errorLog = {
    file = "error.log"
  },

  {
    host = "localhost",
    port = 9091,
    transferLog = { 
      file = "access.log", 
      log = function(logger, req, res)
        logger:info("%s %s %s %d User-Agent=\"%s\" Referer=\"%s\" T=%2f", req.uniqueId, req.method, req.url, req.statusCode, req.headers["user-agent"] or "<null>", req.headers["referer"] or "<null>", req.time.finish - req.time.start)
      end 
    },

    map = function(conn, req, res)
      if xauxi.location(req, "/test/luanode/hello") then
        res:writeHead(200, {["Content-Type"] = "text/plain"})
        res:finish("Hello World")
      elseif xauxi.location(req, "/test/luanode/huge") then
        res:writeHead(200, {["Content-Type"] = "text/plain"})
        res:write(huge)
      else
        xauxi.sendNotFound(req, res)
      end
    end
  }
}

