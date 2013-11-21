require "lunit"

module(..., lunit.testcase, package.seeall)

local cookie = require "xauxi.cookie"

function test_set_empty_value()
  result = cookie.parse("")
  assert_true(#result == 0, "no cookie values at all")
end

function test_set_single_value()
  result = cookie.parse("foo=bar")
  assert_true(#result == 1, "one cookie value")
  assert_equal(result[1].key, "foo", "expect a key")
  assert_equal(result[1].value, "bar", "expect a key")
end

function test_set_single_value_with_spaces()
  result = cookie.parse("foo = bar")
  assert_true(#result == 1, "one cookie value")
  assert_equal(result[1].key, "foo", "expect a key")
  assert_equal(result[1].value, "bar", "expect a key")
end

function test_set_multi_value()
  result = cookie.parse("foo=bar, bla=fasel")
  assert_true(#result == 1, "one cookie value")
  assert_equal(result[1].key, "foo", "expect a key")
  assert_equal(result[1].value, "bar", "expect a key")
  assert_equal(result[1].key, "bla", "expect a key")
  assert_equal(result[1].value, "fasel", "expect a key")
end

