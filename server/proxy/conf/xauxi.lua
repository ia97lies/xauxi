require "config"
xauxi = require "xauxi.engine"
sessionStore = require "xauxi.session"
sessionPlugin = require "plugin.session"

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

function insertStuff(event, req, res, chunk)
  if event == 'begin' and req.session.foobar == nil then
    req.session.foobar = req.headers["foobar"]
    done = true
  end
end

function insertHeader(event, req, res, chunk)
  if event == 'begin' then
    req.headers["foobar"] = req.session.foobar
  end
end

function inputPlugins(event, req, res, chunk)
  chunk = sessionPlugin.input(event, req, res, chunk)
  chunk = insertStuff(event, req, res, chunk)
  chunk = insertHeader(event, req, res, chunk)
  return chunk
end

function outputPlugins(event, req, res, chunk)
  return sessionPlugin.output(event, req, res, chunk)
end

xauxi.run {
  serverRoot = XAUXI_HOME.."/server/proxy/logs",
  errorLog = {
    file = "error.log"
  },
  init = function(logger)
    sessionStore.connect(nil, 60, 120)
    sessionPlugin.init {
      store = sessionStore, 
      cookieName = "xisession",
      interval = 10000,
      logger = logger
    }
  end,

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
        xauxi.pass { 
          conn, req, res,
          host = "localhost", 
          port = 9090 
        }
      elseif xauxi.location(req, "/test/rewrite/request") then
        xauxi.pass {
          conn, req, res, 
          host = "localhost", 
          port = 9090, 
          handleInput = rewriteInputBodyToFoo
        }
      elseif xauxi.location(req, "/test/rewrite/response") then
        xauxi.pass { 
          conn, req, res, 
          host = "localhost", 
          port = 9090, 
          handleOutput = rewriteOutputBodyToFoo
        }
      elseif xauxi.location(req, "/test/luanode") then
        xauxi.pass {
          conn, req, res, 
          host = "localhost", 
          port = 9091
        }
      elseif xauxi.location(req, "/test/session") then
        xauxi.pass {
          conn, req, res, 
          host = "localhost", 
          port = 9090,
          handleInput  = inputPlugins,
          handleOutput = outputPlugins
        }
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
      xauxi.sendNotFound(req, res)
    end
  },

  {
    host = "localhost",
    port = 8443,
    ssl = {
      key = XAUXI_HOME.."/server/proxy/conf/server.key.pem",
      cert = XAUXI_HOME.."/server/proxy/conf/server.cert.pem",
      ca = XAUXI_HOME.."/server/proxy/conf/ca.cert.pem"
    },
    transferLog = { 
      file = "access.log", 
      log = function(logger, req, res)
        logger:info("%s %s %s %d User-Agent=\"%s\" Referer=\"%s\" T=%2f", req.uniqueId, req.method, req.url, req.statusCode, req.headers["user-agent"] or "<null>", req.headers["referer"] or "<null>", req.time.finish - req.time.start)
      end 
    },

    map = function(conn, req, res)
      if xauxi.location(req, "/test/1") then
        xauxi.pass { 
          conn, req, res,
          host = "localhost", 
          port = 9090,
          ssl = {}
        }
      else
        xauxi.sendNotFound(req, res)
      end
    end
  }

}

