require "lunit"

module(..., lunit.testcase, package.seeall)

sessionStore = require "xauxi.session"
local serialize = require "xauxi.serialize"
local plugin = require "plugin.session"

sessionStore.connect(nil, 0, 0)
plugin.init(sessionStore)
function test_new_session()
  local req = {}
  req.headers = {}
  plugin.input("begin", req, res, nil)
  assert_true(req.session ~= nil, "Session object in request expected")
end

function test_session_id()
  local req = {}
  req.headers = {}
  plugin.input("begin", req, res, nil)
  plugin.output("begin", req, res, nil)
  assert_true(req.sessionId ~= nil, "Expect a session id")
end

function test_session_store()
  local req = {}
  req.headers = {}
  plugin.input("begin", req, res, nil)
  req.session.mystuff = "foo"
  plugin.output("begin", req, res, nil)
  local session = sessionStore.get(req.sessionId)
  assert_equal(session.mystuff, "foo", "Expect mystuff in retrieved session")
end

