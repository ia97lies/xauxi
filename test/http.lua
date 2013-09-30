#!./lua_unit

http = require("http")
assertions = 0
run = 0

function getRequest()
  io.write(string.format("getRequest"));
  run = run + 1
  local buf = ""
  local method = nil
  local uri = nil
  local version = nil
  done = http.stream(1, "GET / HTTP/1.1\r\n\r\n", function(r, data) 
    method = r.method 
    uri = r.uri
    version = r.version
    buf = buf..data  
  end)
  if buf ~= "" or method ~= "GET" or uri ~= "/" or version ~= "1.1" or done ~= true then
    io.write(string.format(" body is: "..tostring(buf)))
    io.write(string.format(" method is: "..tostring(method)))
    io.write(string.format(" uri is: "..tostring(uri)))
    io.write(string.format(" version is: "..tostring(version)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.stream(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequest()
  io.write(string.format("postRequest"));
  run = run + 1
  local buf = ""
  done = http.stream(1, "POST / HTTP/1.1\r\nContent-Length: 6\r\n\r\nfoobar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" or done ~= true then
    io.write(string.format(" body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.stream(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequestLineByLine()
  io.write(string.format("postRequestLineByLine"));
  run = run + 1
  local buf = ""
  done = http.stream(1, "POST / HTTP/1.1\r\n", function(r, data) buf = buf..data  end)
  if done ~= false then
    io.write(string.format(" 1. done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
  end
  done = http.stream(1, "Content-Length: 6\r\n", function(r, data) buf = buf..data  end)
  if done ~= false then
    io.write(string.format(" 2. done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
  end
  done = http.stream(1, "\r\n", function(r, data) buf = buf..data  end)
  if done ~= false then
    io.write(string.format(" 3. done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
  end
  done = http.stream(1, "foobar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" or done ~= true then
    io.write(string.format(" 4. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.stream(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequestSplitted()
  io.write(string.format("postRequestSplitted"));
  run = run + 1
  local buf = ""
  http.stream(1, "POST / ", function(r, data) buf = buf..data  end)
  http.stream(1, "HTTP/1.1\r\n", function(r, data) buf = buf..data  end)
  http.stream(1, "Content-Length: 6\r", function(r, data) buf = buf..data  end)
  http.stream(1, "\n", function(r, data) buf = buf..data  end)
  http.stream(1, "\r", function(r, data) buf = buf..data  end)
  http.stream(1, "\n", function(r, data) buf = buf..data  end)
  http.stream(1, "foo", function(r, data) buf = buf..data  end)
  done = http.stream(1, "bar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" or done ~= true then
    io.write(string.format(" body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.stream(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function chunkedResponse()
  io.write(string.format("chunkedResponse"));
  run = run + 1
  local buf = ""
  http.stream(1, "HTTP/1.1 200 OK\r\n", function(r, data) buf = buf..data  end)
  http.stream(1, "Transfer-Encoding: chunked\r\n", function(r, data) buf = buf..data  end)
  http.stream(1, "\r\n", function(r, data) buf = buf..data  end)
  http.stream(1, "6\r\n", function(r, data) buf = buf..data  end)
  http.stream(1, "foobar", function(r, data) buf = buf..data  end)
  done = http.stream(1, "0\r\n\r\n", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" or done ~= true then
    io.write(string.format(" body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.stream(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function test()
  getRequest()
  postRequest()
  postRequestLineByLine()
  postRequestSplitted()
  chunkedResponse()
  return run, assertions
end

