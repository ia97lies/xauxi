require "lunit"

module(..., lunit.testcase, package.seeall)

local route = require "xauxi.route"

function test_url_match()
  local req = {}
  req.url = "/foo/bar/bla"
  assert_true(route.location(req, "/foo/bar/bla"))
  assert_true(route.location(req, "/foo/bar"))
  assert_false(route.location(req, "/foo/bar/bla/notmatch"))
end

function test_url_match_with_query()
  local req = {}
  req.url = "/foo/bar/bla?foo=bar&bla=fasel"
  assert_true(route.location(req, "/foo/bar/bla"))
  assert_true(route.location(req, "/foo/bar"))
  assert_false(route.location(req, "/foo/bar/bla/notmatch"))
end

function test_host()
  local req = {}
  req.headers = {}
  req.headers["host"] = "my.host.ch"
  assert_true(route.host(req, "my.host.ch"))
  assert_false(route.host(req, "my.host.de"))
  assert_true(route.host(req, "my.host."))
  assert_true(route.host(req, ".host.ch"))
  assert_true(route.host(req, ".host."))
end

function test_multi_host()
  local req = {}
  req.headers = {}
  req.headers["host"] = "my.host.ch"
  assert_true(route.host(req, { "my.host.ch" }))
  assert_true(route.host(req, { "my.host.ch", "my.other.ch" }))
  assert_true(route.host(req, { "my.other.ch", "my.host.ch", "foo.bar.ch" }))
  assert_false(route.host(req, { "my.other.ch", "my.host2.ch", "foo.bar.ch" }))
  assert_true(route.host(req, { "my.other.ch", ".ch", "foo.bar.ch" }))
end

