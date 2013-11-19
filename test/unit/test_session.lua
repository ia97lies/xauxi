require "lunit"

module(..., lunit.testcase, package.seeall)

local myTime = 0.0
os.time = function()
  return myTime
end

local session = require "xauxi.session"

function test_set_get()
  -- never expire
  session.connect(session.getInmemoryDriver(), 0, 0)
  session.set("key", "value")
  assert_equal(session.get("key"), "value", "key not found") 
end

function test_set_get_100()
  -- never expire
  session.connect(session.getInmemoryDriver(), 0, 0)
  for i = 1, 100 do
    session.set("key"..i, "value"..i)
  end
  for i = 100, 1, -1 do
    assert_equal(session.get("key"..i), "value"..i, "key not found") 
  end
end

function test_set_get_timeout()
  session.connect(session.getInmemoryDriver(), 10.0, 0)
  session.set("key", "value")
  assert_equal(session.get("key"), "value", "key not found")
  myTime = myTime + 1.0
  assert_equal(session.get("key"), "value", "key not found")
  myTime = myTime + 9.9
  assert_equal(session.get("key"), "value", "key not found")
  myTime = myTime + 10.1 
  assert_true(session.get("key") == nil)
end

function test_set_get_final_timeout()
  session.connect(session.getInmemoryDriver(), 10.0, 20.0)
  session.set("key", "value")
  for i = 1,20 do
    assert_equal(session.get("key"), "value", "key not found")
    myTime = myTime + 1.0
  end
  myTime = myTime + 1.0 
  assert_true(session.get("key") == nil)
end

function test_del()
  session.connect(session.getInmemoryDriver(), 0, 0)
  session.set("key", "value")
  assert_equal(session.get("key"), "value", "key not found")
  session.del("key")
  assert_true(session.get("key") == nil)
end

function test_maintenance()
  session.connect(session.getInmemoryDriver(), 10, 20)
  for i = 1,100 do
    session.set("key"..i, "value"..i)
  end
  assert_true(session.noOfEntries() == 100, string.format("found %d entries", session.noOfEntries()))
  for i = 1,9 do
    myTime = myTime + 1.0
    session.maintenance()
    assert_true(session.noOfEntries() == 100, string.format("found %d entries", session.noOfEntries()))
  end
  myTime = myTime + 1.0
  session.maintenance()
  assert_true(session.noOfEntries() == 0, string.format("found %d entries", session.noOfEntries()))
end

function test_convenience()
  session.connect(nil, 0, 0)
  session.set("key", "value")
  assert_equal(session.get("key"), "value", "key not found") 
end
