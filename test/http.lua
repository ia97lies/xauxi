#!./lua_unit

http = require("http")
assertions = 0
run = 0

-- Mockup connection which is normaly provided by the xauxi kernel
local function _newConnection()
  buf = {}
  local conn = {
    write = function(connection, data)
      table.insert(buf, data)
    end,
    dump = function()
      return table.concat(buf)
    end
  }
  return conn
end

-- Mockup backend connect call
function _connect(host, connection, nextPlugin)
  local backend = _newConnection()
  nextPlugin(backend)
end

function getRequest()
  io.write(string.format("getRequest"));
  run = run + 1
  local buf = ""
  local method = nil
  local uri = nil
  local version = nil
  local conn = _newConnection()
  done = http.frontend(conn, "GET / HTTP/1.1\r\n\r\n", function(r, data) 
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
  http.frontend(conn, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequest()
  io.write(string.format("postRequest"));
  run = run + 1
  local buf = ""
  local conn = _newConnection()
  done = http.frontend(conn, "POST / HTTP/1.1\r\nContent-Length: 6\r\n\r\nfoobar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" or done ~= true then
    io.write(string.format(" body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.frontend(conn, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequestLineByLine()
  io.write(string.format("postRequestLineByLine"));
  run = run + 1
  local buf = ""
  local conn = _newConnection()
  done = http.frontend(conn, "POST / HTTP/1.1\r\n", function(r, data) buf = buf..data  end)
  if done ~= false then
    io.write(string.format(" 1. done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
  end
  done = http.frontend(conn, "Content-Length: 6\r\n", function(r, data) buf = buf..data  end)
  if done ~= false then
    io.write(string.format(" 2. done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
  end
  done = http.frontend(conn, "\r\n", function(r, data) buf = buf..data  end)
  if done ~= false then
    io.write(string.format(" 3. done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
  end
  done = http.frontend(conn, "foobar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" or done ~= true then
    io.write(string.format(" 4. body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.frontend(conn, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequestSplitted()
  io.write(string.format("postRequestSplitted"));
  run = run + 1
  local buf = ""
  local conn = _newConnection()
  http.frontend(conn, "POST / ", function(r, data) buf = buf..data  end)
  http.frontend(conn, "HTTP/1.1\r\n", function(r, data) buf = buf..data  end)
  http.frontend(conn, "Content-Length: 6\r", function(r, data) buf = buf..data  end)
  http.frontend(conn, "\n", function(r, data) buf = buf..data  end)
  http.frontend(conn, "\r", function(r, data) buf = buf..data  end)
  http.frontend(conn, "\n", function(r, data) buf = buf..data  end)
  http.frontend(conn, "foo", function(r, data) buf = buf..data  end)
  done = http.frontend(conn, "bar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" or done ~= true then
    io.write(string.format(" body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.frontend(conn, nil, nil);
  io.write(string.format(" ok\n"));
end
-- TODO  this should actually use backend instead frontend
function chunkedResponse()
  io.write(string.format("chunkedResponse"));
  run = run + 1
  local buf = ""
  local conn = _newConnection()
  http.frontend(conn, "HTTP/1.1 200 OK\r\n", function(r, data) buf = buf..data  end)
  http.frontend(conn, "Transfer-Encoding: chunked\r\n", function(r, data) buf = buf..data  end)
  http.frontend(conn, "\r\n", function(r, data) buf = buf..data  end)
  http.frontend(conn, "6\r\n", function(r, data) buf = buf..data  end)
  http.frontend(conn, "foobar", function(r, data) buf = buf..data  end)
  done = http.frontend(conn, "0\r\n\r\n", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" or done ~= true then
    io.write(string.format(" body is: "..tostring(buf)))
    io.write(string.format(" done is: "..tostring(done)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.frontend(conn, nil, nil);
  io.write(string.format(" ok\n"));
end

function getRequestToBackend()
  io.write(string.format("getRequestToBackend"));
  run = run + 1
  local conn = _newConnection()
  local backend
  local request
  http.frontend(conn, "GET / HTTP/1.1\r\nHost: localhost:8090\r\n\r\n", function(r, data) 
    request = r 
  end)
  connect = _connect
  http.backend(request, "localhost:8090", nil, function(connection) backend = connection end)
  local buf = backend.dump()
  if buf ~= "GET / HTTP/1.1\r\nHost: localhost:8090\r\n\r\n" then
    io.write(string.format(" request is: "..tostring(buf)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.frontend(conn, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequestToBackend()
  io.write(string.format("postRequestToBackend"));
  run = run + 1
  local conn = _newConnection()
  local backend
  http.frontend(conn, "POST / HTTP/1.1\r\nHost: localhost:8090\r\nContent-Length: 8\r\n\r\nfoobar\r\n", function(r, data) 
    request = r 
  end)
  connect = _connect
  -- TODO: call this inside anonyomous http.frontend function
  -- in reality the http.backend is called inside anonyomous http.frontend function
  http.backend(request, "localhost:8090", "foobar\r\n", function(connection) backend = connection end)
  local buf = backend.dump()
  if buf ~= "POST / HTTP/1.1\r\nHost: localhost:8090\r\nContent-Length: 8\r\n\r\nfoobar\r\n" then
    io.write(string.format(" request is: "..tostring(buf)))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.frontend(conn, nil, nil);
  io.write(string.format(" ok\n"));
end

function test()
  getRequest()
  postRequest()
  postRequestLineByLine()
  postRequestSplitted()
  chunkedResponse()
  getRequestToBackend()
  postRequestToBackend()
  return run, assertions
end

