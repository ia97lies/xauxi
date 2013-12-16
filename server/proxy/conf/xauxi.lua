require "config"
xauxi = require "xauxi.engine"
route = require "xauxi.route"
session = require "xauxi.session"
agent = require "xauxi.agent"
ha = require "xauxi.ha"

sessionPlugin = require "plugin.session"

local distributed = ha.Distributed()
local paired = agent.Paired()

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
  serverRoot = XAUXI_HOME.."/server/proxy",
  errorLog = {
    file = "error.log"
  },
  init = function(logger)
    session.connect(nil, 60, 120)
    sessionPlugin.init {
      store = session, 
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

    map = function(server, req, res)
      if route.location(req, "/test/1") then
        xauxi.pass { 
          server, req, res,
          agent = paired,
          host = "localhost:9090"
        }
      elseif route.location(req, "/test/balanced/session") then
        xauxi.pass { 
          server, req, res,
          selector = distributed,
          host = { "localhost:9090", "localhost:9092" },
          chain = { 
            input  = sessionPlugin.input, 
            output = sessionPlugin.output
          }
        }
      elseif route.location(req, "/test/balanced") then
        xauxi.pass { 
          server, req, res,
          selector = distributed,
          host = { "localhost:9090", "localhost:9092" }
        }
      elseif route.location(req, "/test/rewrite/request") then
        xauxi.pass {
          server, req, res, 
          agent = paired,
          host = "localhost:9090", 
          chain = { input = rewriteInputBodyToFoo }
        }
      elseif route.location(req, "/test/rewrite/response") then
        xauxi.pass { 
          server, req, res, 
          agent = paired,
          host = "localhost:9090", 
          chain = { output = rewriteOutputBodyToFoo }
        }
      elseif route.location(req, "/test/luanode") then
        xauxi.pass {
          server, req, res, 
          agent = paired,
          host = "localhost:9091"
        }
      elseif route.location(req, "/test/session") then
        xauxi.pass {
          server, req, res, 
          agent = paired,
          host = "localhost:9090",
          chain = { 
            input  = inputPlugins, 
            output = outputPlugins
          }
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

    map = function(server, req, res)
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

    map = function(server, req, res)
      if route.location(req, "/test/1") then
        xauxi.pass { 
          server, req, res,
          agent = paired,
          ssl = {},
          host = "localhost:9090"
        }
      else
        xauxi.sendNotFound(req, res)
      end
    end
  }

}

