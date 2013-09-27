#!./lua_unit

Connection = require("connection")
Request = require("request")
assertions = 0
run = 0

function readRequestHeaders()
  io.write(string.format("readRequestHeaders"));
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.connection:pushData("GET /index.html HTTP/1.1\r\n")
  r.connection:pushData("User-Agent: lua-test\r\n")
  r.connection:pushData("Host: localhost:8080\r\n")
  r.connection:pushData("\r\n")
  local done = r:readHeader()
  if done ~= true then
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  if r.method ~= "GET" then
    io.write(string.format(" method is: "..tostring(r.method)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  if r.uri ~= "/index.html" then
    io.write(string.format(" uri is: "..tostring(r.uri)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  if r.version ~= "1.1" then
    io.write(string.format(" version is: "..tostring(r.version)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  if r.headers["User-Agent"].val ~= "lua-test" then
    io.write(string.format(" User-Agent is: "..tostring(r.headers["User-Agent"].val)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  if r.headers["Host"].val ~= "localhost:8080" then
    io.write(string.format(" Host is: "..tostring(r.headers["Host"].val)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

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

function readContentLengthBodySplitted()
  io.write(string.format("readContentLengthBodySplitted"));
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

function readContentLengthBodySplittedWithRest()
  io.write(string.format("readContentLengthBodySplittedWithRest"));
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

function readContentLengthBodySplittedWithRest2()
  io.write(string.format("readContentLengthBodySplittedWithRest2"));
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

function readChunkedBodySplitted()
  io.write(string.format("readChunkedBodySplitted"));
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c

  r:chunkedEncodingFilter("6\r", function(r, data) buf = buf..data  end)
  r:chunkedEncodingFilter("\nfoo", function(r, data) buf = buf..data  end)
  r:chunkedEncodingFilter("bar\r\n", function(r, data) buf = buf..data  end)
  r:chunkedEncodingFilter("0\r\n", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    io.write(string.format(" body is: \""..buf.."\""))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readChunkedBodyWithRest()
  io.write(string.format("readChunkedBodyWithRest"));
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c

  r:chunkedEncodingFilter("6\r\nfoobar\r\n0\r\nblafasel", function(r, data) buf = buf..data  end)
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

function readChunkedBodySplittedWithRest()
  io.write(string.format("readChunkedBodySplittedWithRest"));
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c

  r:chunkedEncodingFilter("6\r", function(r, data) buf = buf..data  end)
  r:chunkedEncodingFilter("\nfoo", function(r, data) buf = buf..data  end)
  r:chunkedEncodingFilter("bar\r\n", function(r, data) buf = buf..data  end)
  r:chunkedEncodingFilter("0\r\nb", function(r, data) buf = buf..data  end)
  r:chunkedEncodingFilter("lafas", function(r, data) buf = buf..data  end)
  r:chunkedEncodingFilter("el", function(r, data) buf = buf..data  end)
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

function test()
  readRequestHeaders() 
  readContentLengthBody() 
  readContentLengthBodyWithRest() 
  readContentLengthBodyWithRest2() 
  readContentLengthBodySplitted() 
  readContentLengthBodySplittedWithRest() 
  readContentLengthBodySplittedWithRest2() 
  readChunkedBody() 
  readChunkedBodySplitted() 
  readChunkedBodyWithRest() 
  readChunkedBodySplittedWithRest() 
  return run, assertions
end
