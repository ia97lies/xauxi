#!./lua_unit

http = require("http")
assertions = 0
run = 0

function getRequest()
  io.write(string.format("getRequest"));
  run = run + 1
  local buf = ""
  http.filter(1, "GET / HTTP/1.1\r\n\r\n", function(r, data) buf = buf..data  end)
  if buf ~= "" then
    io.write(string.format("body is: \""..buf.."\""))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.filter(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequest()
  io.write(string.format("postRequest"));
  run = run + 1
  local buf = ""
  http.filter(1, "POST / HTTP/1.1\r\nContent-Length: 6\r\n\r\nfoobar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    io.write(string.format("body is: \""..buf.."\""))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.filter(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequestSplitLine()
  io.write(string.format("postRequest"));
  run = run + 1
  local buf = ""
  http.filter(1, "POST / HTTP/1.1\r\n", function(r, data) buf = buf..data  end)
  http.filter(1, "Content-Length: 6\r\n", function(r, data) buf = buf..data  end)
  http.filter(1, "\r\n", function(r, data) buf = buf..data  end)
  http.filter(1, "foobar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    io.write(string.format("body is: \""..buf.."\""))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.filter(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function postRequestSplit()
  io.write(string.format("postRequest"));
  run = run + 1
  local buf = ""
  http.filter(1, "POST / ", function(r, data) buf = buf..data  end)
  http.filter(1, "HTTP/1.1\r\n", function(r, data) buf = buf..data  end)
  http.filter(1, "Content-Length: 6\r", function(r, data) buf = buf..data  end)
  http.filter(1, "\n", function(r, data) buf = buf..data  end)
  http.filter(1, "\r", function(r, data) buf = buf..data  end)
  http.filter(1, "\n", function(r, data) buf = buf..data  end)
  http.filter(1, "foo", function(r, data) buf = buf..data  end)
  http.filter(1, "bar", function(r, data) buf = buf..data  end)
  if buf ~= "foobar" then
    io.write(string.format("body is: \""..buf.."\""))
    io.write(string.format(" failed\n"));
    assertions = assertions + 1
    return
  end
  http.filter(1, nil, nil);
  io.write(string.format(" ok\n"));
end

function test()
  getRequest() 
  postRequest() 
  postRequestSplitLine() 
  postRequestSplit() 
  return run, assertions
end

