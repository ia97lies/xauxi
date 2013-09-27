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
  r.connection:pushData("foobar")
  r.headers["Content-Length"] = 6
  local done = r:contentLengthBody(function(r, data) buf = buf..data  end)
  if buf ~= "foobar" and done ~= true then
    io.write(string.format(" body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readContentLengthBodyWithLeftover()
  io.write(string.format("readContentLengthBodyWithLeftover"));
  run = run + 1
  local buf = ""
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.connection:pushData("foobarblafasel")
  r.headers["Content-Length"] = 6
  local done = r:contentLengthBody(function(r, data) buf = buf..data  end)
  if buf ~= "foobar" and done ~= true then
    io.write(string.format(" 1. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end

  local buf = ""
  r.headers["Content-Length"] = 8
  local done = r:contentLengthBody(function(r, data) buf = buf..data  end)
  if buf ~= "blafasel" and done ~= true then
    io.write(string.format(" 2. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end

  local buf = ""
  r.headers["Content-Length"] = 8
  local done = r:contentLengthBody(function(r, data) buf = buf..data  end)
  if buf ~= "" and done ~= false then
    io.write(string.format(" 3. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"));
end

function readContentLengthBodyStreamed()
  io.write(string.format("readContentLengthBodyWithLeftover"));
  run = run + 1
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.connection:pushData("foo")
  r.headers["Content-Length"] = 6
  local buf = ""
  local done = r:contentLengthBody(function(r, data) buf = buf..data  end)
  if buf ~= "foo" and done ~= false then
    io.write(string.format(" 1. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  r.connection:pushData("bar")
  local done = r:contentLengthBody(function(r, data) buf = buf..data  end)
  if buf ~= "bar" and done ~= true then
    io.write(string.format(" 1. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readChunkedNullChunk()
  io.write(string.format("readChunkedNullChunk"));
  run = run + 1
  c = Connection.new()
  r = Request.new() 
  r.connection = c
  r.connection:pushData("\r\n0\r\n\r\n")
  local buf = ""
  local done = r:chunkedEncodingBody(function(r, data) buf = buf..data  end)
  if buf ~= "" and done ~= true then
    io.write(string.format(" 1. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function test()
  readRequestHeaders() 
  readContentLengthBody() 
  readContentLengthBodyWithLeftover() 
  readContentLengthBodyStreamed() 
  readChunkedNullChunk() 
  return run, assertions
end
