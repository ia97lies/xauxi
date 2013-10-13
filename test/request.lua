#!./lua_unit

queue = require("queue")
Request = require("request")
assertions = 0
run = 0

function readRequestHeaders()
  io.write(string.format("readRequestHeaders"));
  run = run + 1
  local buf = ""
  q = queue.new()
  r = Request.new() 
  r.queue = q
  r.queue:pushData("GET /index.html HTTP/1.1\r\n")
  r.queue:pushData("User-Agent: lua-test\r\n")
  r.queue:pushData("Host: localhost:8080\r\n")
  r.queue:pushData("\r\n")
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
  if r.headers["User-Agent"].value ~= "lua-test" then
    io.write(string.format(" User-Agent is: "..tostring(r.headers["User-Agent"].val)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  if r.headers["Host"].value ~= "localhost:8080" then
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
  q = queue.new()
  r = Request.new() 
  r.queue = q
  r.queue:pushData("foobar")
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
  q = queue.new()
  r = Request.new() 
  r.queue = q
  r.queue:pushData("foobarblafasel")
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
  q = queue.new()
  r = Request.new() 
  r.queue = q
  r.queue:pushData("foo")
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
  r.queue:pushData("bar")
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
  q = queue.new()
  r = Request.new() 
  r.queue = q
  r.queue:pushData("\r\n0\r\n\r\n")
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

function readChunkedOneChunk()
  io.write(string.format("readChunkedOneChunk"));
  run = run + 1
  q = queue.new()
  r = Request.new() 
  r.queue = q
  r.queue:pushData("\r\n6\r\n")
  r.queue:pushData("foobar")
  r.queue:pushData("\r\n0\r\n\r\n")
  local buf = ""
  local done = r:chunkedEncodingBody(function(r, data) buf = buf..data  end)
  if buf ~= "foobar" and done ~= true then
    io.write(string.format(" 1. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readChunkedChunksWithLeftover()
  io.write(string.format("readChunkedChunksWithLeftover"));
  run = run + 1
  q = queue.new()
  r = Request.new() 
  r.queue = q
  r.queue:pushData("\r\n6\r\n")
  r.queue:pushData("foobar")
  r.queue:pushData("\r\na\r\n")
  r.queue:pushData("blafasel12")
  r.queue:pushData("\r\n0\r\n\r\n")
  r.queue:pushData("rabarberrabarber")
  local buf = ""
  local done = r:chunkedEncodingBody(function(r, data) buf = buf..data  end)
  if buf ~= "foobarblafasel12" and done ~= true then
    io.write(string.format(" 1. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"));
end

function readChunkedChunksStreamed()
  io.write(string.format("readChunkedChunksStreamed"));
  run = run + 1
  q = queue.new()
  r = Request.new() 
  r.queue = q
  r.queue:pushData("\r\n6\r\n")
  r.queue:pushData("foo")
  local buf = ""
  local done = r:chunkedEncodingBody(function(r, data) buf = buf..data  end)
  if buf ~= "foo" and done ~= false then
    io.write(string.format(" 1. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  r.queue:pushData("bar")
  r.queue:pushData("\r\na")
  local buf = ""
  local done = r:chunkedEncodingBody(function(r, data) buf = buf..data  end)
  if buf ~= "bar" and done ~= false then
    io.write(string.format(" 2. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
    r.queue:pushData("\r\n")
    local buf = ""
    local done = r:chunkedEncodingBody(function(r, data) buf = buf..data  end)
    if buf ~= "" and done ~= false then
      io.write(string.format(" 3. body is: "..tostring(buf)))
      io.write(string.format(" done is: "..tostring(done)))
      io.write(string.format(" failed\n"));
      assertions = assertions + 1
      return
    end
  r.queue:pushData("blafasel12")
  r.queue:pushData("\r\n0\r\n\r\n")
  local buf = ""
  local done = r:chunkedEncodingBody(function(r, data) buf = buf..data  end)
  if buf ~= "blafasel12" and done ~= true then
    io.write(string.format(" 4. body is: "..tostring(buf)))
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
  readChunkedOneChunk() 
  readChunkedChunksWithLeftover() 
  readChunkedChunksStreamed() 
  return run, assertions
end
