require "lunit"

module(..., lunit.testcase, package.seeall)

local cookie = require "xauxi.cookie"

function test_set_empty_value()
  result = cookie.parse("")
end

function test_set_single_value()
  result = cookie.parse("foo=bar")
  assert_equal(result.foo, "bar", "expect a value")
end

function test_set_single_value_with_spaces()
  result = cookie.parse("foo = bar")
  assert_equal(result.foo, "bar", "expect a value")
end

function test_set_multi_value()
  result = cookie.parse("foo=bar, bla=fasel")
  assert_equal(result.foo, "bar", "expect a value")
  assert_equal(result.bla, "fasel", "expect a value")
end

function test_set_quoted_value()
  result = cookie.parse("foo=\"bar\"")
  assert_equal(result.foo, "bar", "expect a value")
end

