#!./lua_unit

Connection = require("connection")
Request = require("request")
assertions = 0
run = 0

function readContentLengthBody()
  io.write(string.format("readContentLengthBody"));
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.headers["Content-Length"] = 6
  r:contentLengthFilter("foobar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    io.write(string.format(" body is: \""..buf.."\""))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readContentLengthBodyWithRest()
  io.write(string.format("readContentLengthBodyWithRest"));
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.headers["Content-Length"] = 6
  r:contentLengthFilter("foobarblafasel", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    io.write(string.format(" body is: \""..buf.."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  if c:getBuf() ~= "blafasel" then
    io.write(string.format(" rest is: \""..c:getBuf().."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readContentLengthBodyWithRest2()
  io.write(string.format("readContentLengthBodyWithRest2"));
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
    io.write(string.format(" body is: \""..buf.."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  if c:getBuf() ~= "blafasel" then
    io.write(string.format(" rest is: \""..c:getBuf().."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readContentLengthBodyInChunks()
  io.write(string.format("readContentLengthBodyInChunks"));
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
    io.write(string.format(" body is: \""..buf.."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readContentLengthBodyInChunksWithRest()
  io.write(string.format("readContentLengthBodyInChunksWithRest"));
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
    io.write(string.format(" body is: \""..buf.."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  if c:getBuf() ~= "blafasel" then
    io.write(string.format(" rest is: \""..c:getBuf().."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readContentLengthBodyInChunksWithRest2()
  io.write(string.format("readContentLengthBodyInChunksWithRest2"));
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
    io.write(string.format(" body is: \""..buf.."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  if c:getBuf() ~= "blafasel" then
    io.write(string.format(" rest is: \""..c:getBuf().."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readChunkedBody()
  io.write(string.format("readChunkedBody"));
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c

  r:chunkedEncodingFilter("6\r\nfoobar\r\n0\r\n", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    io.write(string.format(" body is: \""..buf.."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function test()
  readContentLengthBody() 
  readContentLengthBodyWithRest() 
  readContentLengthBodyWithRest2() 
  readContentLengthBodyInChunks() 
  readContentLengthBodyInChunksWithRest() 
  readContentLengthBodyInChunksWithRest2() 
  readChunkedBody() 
  return run, assertions
end
