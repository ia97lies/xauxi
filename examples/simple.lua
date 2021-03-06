-- TODO: Adjust the package.path so it will find luanode, lualogging and xauxi libs!
package.path = package.path..";/path/to/your/xauxi/lib/?.lua;/path/to/your/lualogging/src/?.lua;./?.lua"
xauxi = require "xauxi.engine"
route = require "xauxi.route"

-- Input rewriting data from frontend to Backend
function rewriteRequestBody(event, req, res, chunk)
  -- of course you can do funky stuff with the data pass
  -- to backend
  --
  -- event can have eigher 'begin', 'end' and 'data'
  -- setting headers in request only works on event 'begin'
  -- on 'end' you are done no more chunks will arrive.
  --
  -- of course you can chain more filters here.
  return chunk
end

-- Output rewriting data from backend to frontend
function rewriteResponseBody(event, req, res, chunk)
  -- of course you can do funky stuff with the data pass
  -- to backend
  --
  -- event can have eigher 'begin', 'end' and 'data'
  -- setting headers in request only works on event 'begin'
  -- on 'end' you are done no more chunks will arrive.
  --
  -- of course you can chain more filters here.
  return chunk
end

-- this is the actual config with a similar structure like apaches httpd.conf
xauxi.run {
  serverRoot = "/your/server/root",
  errorLog = {
    file = "error.log"
  },

  -- server section like vhost on apache
  {
    host = "localhost",
    port = 8080,
    transferLog = { 
      file = "access.log", 
      log = function(logger, req, res)
        logger:info("%s %s %s %d User-Agent=\"%s\" Referer=\"%s\" T=%2f", req.uniqueId, req.method, req.url, req.statusCode, req.headers["user-agent"] or "<null>", req.headers["referer"] or "<null>", req.time.finish - req.time.start)
      end 
    },

    map = function(conn, req, res)
      if route.location(req, "/test/1") then
        xauxi.pass {
          conn, req, res, 
          host = "localhost", 
          port = 9090
        }
      elseif route.location(req, "/test/rewrite") then
        -- filters are optional
        xauxi.pass {
          conn, req, res, 
          host = "localhost", 
          port = 9090, 
          chain = {
            input = rewriteRequestBody,
            output = rewriteResponseBody
          }
        }
      else
        xauxi.sendNotFound(conn, req, res)
      end
    end
  }

  -- more server sections are allowed here
}

