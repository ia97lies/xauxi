xauxi = require "XauxiEngine"

function rewriteInputBodyToFoo(event, req, res, chunk)
  if event == 'begin' then
    req.headers["content-length"] = nil
  elseif event == 'end' then
    return "foo"
  else
    return nil
  end
end

function rewriteOutputBodyToFoo(event, req, res, chunk)
  if event == 'begin' then
    res.headers["content-length"] = nil
  elseif event == 'end' then
    return "foo"
  else
    return nil
  end
end

xauxi.run {
  errorLog = {
    file = "error.log"
  },

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
      if xauxi.location(req, "/test/1") then
        xauxi.pass(conn, req, res, "localhost", 9090)
      elseif xauxi.location(req, "/test/rewrite/request") then
        xauxi.pass(conn, req, res, "localhost", 9090, rewriteInputBodyToFoo)
      elseif xauxi.location(req, "/test/rewrite/response") then
        xauxi.pass(conn, req, res, "localhost", 9090, nil, rewriteOutputBodyToFoo)
      elseif xauxi.location(req, "/test/luanode") then
        xauxi.pass(conn, req, res, "localhost", 9091)
      else
        xauxi.sendNotFound(req, res)
      end
    end
  },

  {
    host = "localhost",
    port = 8081,
    transferLog = { 
      file = "access.log", 
      log = function(logger, req, res)
        logger:info("%s %s %s %d User-Agent=\"%s\" Referer=\"%s\" T=%2f", req.uniqueId, req.method, req.url, req.statusCode, req.headers["user-agent"] or "<null>", req.headers["referer"] or "<null>", req.time.finish - req.time.start)
      end 
    },

    map = function(conn, req, res)
      xauxi.sendNotFound(conn, req, res)
    end

  }
}

