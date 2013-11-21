require "lunit"

module(..., lunit.testcase, package.seeall)

sessionStore = require "xauxi.session"
local serialize = require "xauxi.serialize"
local plugin = require "plugin.session"

sessionStore.connect(nil, 0, 0)
plugin.init(sessionStore, "xisession")
function test_new_session()
  local req = {}
  req.headers = {}
  plugin.input("begin", req, res, nil)
  assert_true(req.session ~= nil, "Session object in request expected")
end

function test_session_id()
  local req = {}
  req.headers = {}
  local res = {}
  res.headers = {}
  plugin.input("begin", req, res, nil)
  plugin.output("begin", req, res, nil)
  assert_true(req.sessionId ~= nil, "Expect a session id")
  assert_equal("xisession="..req.sessionId, res.headers["set-cookie"][1], "expect sessionId as in set-cookie")
end

function test_set_session()
  local req = {}
  req.headers = {}
  local res = {}
  res.headers = {}
  plugin.input("begin", req, res, nil)
  req.session.mystuff = "foo"
  plugin.output("begin", req, res, nil)
  local session = sessionStore.get(req.sessionId)
  assert_equal(session.mystuff, "foo", "Expect mystuff in retrieved session")
end

function test_get_session()
  local req = {}
  req.headers = {}
  local res = {}
  res.headers = {}
  plugin.input("begin", req, res, nil)
  req.session.mystuff2 = "foo2"
  plugin.output("begin", req, res, nil)
  req.headers["cookie"] = "xisession=1"
  assert_true(false, "Implement this test but wait for a cookie parser first")
end
