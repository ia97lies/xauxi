#!./lua_unit

Connection = require("connection")
Request = require("request")
assertions = 0
run = 0

function readContentLengthBody()
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.headers["Content-Length"] = 6
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    print("body is: \""..buf.."\"")
    print("readContentLengthBody failed");
    assertions = assertions + 1
    return
  end
end

function readContentLengthBodyWithRest()
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.headers["Content-Length"] = 6
  r:contentLengthFilter("foobarblafasel", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    print("body is: \""..buf.."\"")
    print("readContentLengthBodyWithRest failed");
    assertions = assertions + 1
    return
  end
  if c.buf ~= "blafasel" then
    print("rest is: \""..c.buf.."\"")
    print("readContentLengthBodyWithRest failed");
    assertions = assertions + 1
    return
  end
end

function readContentLengthBodyWithRest2()
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.headers["Content-Length"] = 6 
  r:contentLengthFilter("foobarb", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("la", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("fasel", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    print("body is: \""..buf.."\"")
    print("readContentLengthBodyWithRest2 failed");
    assertions = assertions + 1
    return
  end
  if c.buf ~= "blafasel" then
    print("rest is: \""..c.buf.."\"")
    print("readContentLengthBodyWithRest2 failed");
    assertions = assertions + 1
    return
  end
end

function readContentLengthBodyInChunks()
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.headers["Content-Length"] = 21 
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("bar", function(r, data) buf = buf..data  end)
  if buf ~= "foobarfoobarfoobarbar" then
    print("body is: \""..buf.."\"")
    print("readContentLengthBodyInChunks failed");
    assertions = assertions + 1
    return
  end
end

function readContentLengthBodyInChunksWithRest()
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.headers["Content-Length"] = 21 
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("bar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("bla", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("fasel", function(r, data) buf = buf..data  end)
  if buf ~= "foobarfoobarfoobarbar" then
    print("body is: \""..buf.."\"")
    print("readContentLengthBodyInChunksWithRest failed");
    assertions = assertions + 1
    return
  end
  if c.buf ~= "blafasel" then
    print("rest is: \""..c.buf.."\"")
    print("readContentLengthBodyInChunksWithRest failed");
    assertions = assertions + 1
    return
  end
end

function readContentLengthBodyInChunksWithRest2()
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.headers["Content-Length"] = 21 
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("barb", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("la", function(r, data) buf = buf..data  end)
  r:contentLengthFilter("fasel", function(r, data) buf = buf..data  end)
  if buf ~= "foobarfoobarfoobarbar" then
    print("body is: \""..buf.."\"")
    print("readContentLengthBodyInChunksWithRest failed");
    assertions = assertions + 1
    return
  end
  if c.buf ~= "blafasel" then
    print("rest is: \""..c.buf.."\"")
    print("readContentLengthBodyInChunksWithRest failed");
    assertions = assertions + 1
    return
  end
end

function test()
  readContentLengthBody() 
  readContentLengthBodyWithRest() 
  readContentLengthBodyWithRest2() 
  readContentLengthBodyInChunks() 
  readContentLengthBodyInChunksWithRest() 
  readContentLengthBodyInChunksWithRest2() 
  return run, assertions
end
