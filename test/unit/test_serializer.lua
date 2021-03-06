require "lunit"

module(..., lunit.testcase, package.seeall)

local serializer = require "xauxi.serialize"

function test_serialize_not_a_table()
  assert_error("Not a session table", function() serializer.serialize("not a table") end)
end

function test_serialize_empty_table()
  assert_equal("{}", serializer.serialize({}))
end

function test_serialize_one_int_entry()
  assert_equal("{1}", serializer.serialize({1}))
end

function test_serialize_int_entris()
  assert_equal("{1,2,3,4}", serializer.serialize({1,2,3,4}))
end

function test_serialize_strings()
  assert_equal("{\"foo\",\"bar\"}", serializer.serialize({"foo","bar"}))
end

function test_serialize_strings_and_ints()
  assert_equal("{\"foo\",1,\"bar\",10,122}", serializer.serialize({"foo",1,"bar",10,122}))
end

function test_serialize_table_in_table()
  assert_equal("{{}}", serializer.serialize({{}}))
end

function test_serialize_many_tables()
  assert_equal("{{},{},{},{}}", serializer.serialize({{},{},{},{}}))
end

function test_serialize_tables_ints_strings()
  assert_equal("{{1,2,3},{\"foo\",\"bar\",\"bla\"},{1,\"bar\",20},{}}", serializer.serialize({{1,2,3},{"foo","bar","bla"},{1,"bar",20},{}}))
end

function test_serialize_named_pair()
  assert_equal("{foo=\"bar\"}", serializer.serialize({foo="bar"}))
end

function test_serialize_mixed()
  --not the same order, as key value paris are hashed unsorted
  --maybe this test can fail in the future, if hashing changes
  assert_equal("{1,2,3,t={1,2,bla=\"fasel\"},foo=\"bar\"}", serializer.serialize({foo="bar",1,2,3,t={1,2,bla="fasel"}}))
end

function test_deserialize()
  local t = serializer.deserialize("{1,2,3,foo=\"bar\"}")
  assert_equal("bar", t.foo)
  assert_equal(1, t[1])
  assert_equal(2, t[2])
  assert_equal(3, t[3])
end

