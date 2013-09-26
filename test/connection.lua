#!./lua_unit

connection = require("connection")
assertions = 0
run = 0

function getBufNoData()
  io.write(string.format("getBuf"))
  run = run + 1
  local c = connection.new()
  local buf, more = c:getData(1)
  if buf ~= nil or more ~= false then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" more is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function getBufOneByte()
  io.write(string.format("getBufOneByte"))
  run = run + 1
  local c = connection.new()
  c:pushData("1")
  -- first run, there must be one byte
  local buf, more = c:getData(1)
  if buf ~= "1" or more ~= false then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" more is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- second run, there must be nil 
  buf, more = c:getData(1)
  if buf ~= nil or more ~= false then
    io.write(string.format(" second run buf is "..tostring(buf)))
    io.write(string.format(" more is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function getBufByteByByte()
  io.write(string.format("getBufByteByByte"))
  run = run + 1
  local c = connection.new()
  c:pushData("1")
  c:pushData("2")
  -- job to get one byte
  local buf, more = c:getData(1)
  if buf ~= "1" or more ~= true then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    io.write(string.format(" more is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- job finish mark nil, true as there are still data
  local buf, more = c:getData(1)
  if buf ~= nil or more ~= true then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    io.write(string.format(" more is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- next job to get one byte
  local buf, more = c:getData(1)
  if buf ~= "2" or more ~= false then
    io.write(string.format(" 3. buf is "..tostring(buf)))
    io.write(string.format(" more is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- job finish mark nil, true as there are still data
  local buf, more = c:getData(1)
  if buf ~= nil or more ~= false then
    io.write(string.format(" 4 buf is "..tostring(buf)))
    io.write(string.format(" more is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getBufTwoBytesSplitted()
  io.write(string.format("getBufTwoBytesSplitted"))
  run = run + 1
  local c = connection.new()
  c:pushData("1")
  c:pushData("2")
  -- first run, there must be "1" 
  local buf = c:getData(1)
  if buf ~= "1" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- second run, there must be "2" 
  local buf = c:getData(1)
  if buf ~= "2" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- third run, there must be nil 
  buf = c:getData(1)
  if buf ~= nil then
    io.write(string.format(" second run buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getBufDataSplitted()
  io.write(string.format("getBufDataSplitted"))
  run = run + 1
  local c = connection.new()
  c:pushData("1234567")
  c:pushData("890abcdefghijklmnopqrst")
  c:pushData("uvwxyz")
  c:pushData("yuhee d")
  c:pushData("as ganze alp")
  c:pushData("habeth")
  -- first run
  local buf = c:getData(10)
  if buf ~= "1234567890" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- second run
  local buf = c:getData(26)
  if buf ~= "abcdefghijklmnopqrstuvwxyz" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- third run
  local buf = c:getData(24)
  if buf ~= "yuhee das ganze alphabet" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- forth run
  local buf = c:getData(10)
  if buf ~= nil then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- fifth run
  c:pushData("123456789")
  local buf = c:getData(10)
  if buf ~= "h123456789" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- last run
  local buf = c:getData(10)
  if buf ~= nil then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function getLineNoData()
  io.write(string.format("getLineNoData"))
  run = run + 1
  local c = connection.new()
  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function getLineEmptyLine()
  io.write(string.format("getEmptyLine"))
  run = run + 1
  local c = connection.new()
  c:pushData("\r\n")
  local buf = c:getLine()

  -- first run
  if buf ~= "" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- second run
  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" buf is not nil"..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function getLineOneLine()
  io.write(string.format("getLineOneLine"))
  run = run + 1
  local c = connection.new()
  c:pushData("123456789\r\n")
  local buf = c:getLine()

  -- first run
  if buf ~= "123456789" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- second run
  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function getLineMultiLineSplitted()
  io.write(string.format("getLineMultiLineSplitted"))
  run = run + 1
  local c = connection.new()
  c:pushData("1")
  c:pushData("23456")
  c:pushData("789\r\nabcdefg")
  c:pushData("\r\n")

  -- first run
  local buf = c:getLine()
  if buf ~= "123456789" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- second run
  local buf = c:getLine()
  if buf ~= "abcdefg" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- third run
  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function getLineHttpRequest()
  io.write(string.format("getLineHttpRequest"))
  run = run + 1
  local c = connection.new()
  c:pushData("GET / HTTP/1.1\r")
  c:pushData("\nUser-Agen")
  c:pushData("t: lua-test")
  c:pushData("\r\nH")
  c:pushData("ost: localhost:8080\r\n")
  c:pushData("\r")
  c:pushData("\n")

  local buf = c:getLine()
  if buf ~= "GET / HTTP/1.1" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  local buf = c:getLine()
  if buf ~= "User-Agent: lua-test" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  local buf = c:getLine()
  if buf ~= "Host: localhost:8080" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  local buf = c:getLine()
  if buf ~= "" then
    io.write(string.format(" buf should be empty but is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" buf should be nil but is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function test()
  getBufNoData() 
  getBufOneByte() 
  getBufByteByByte() 
  getBufTwoBytesSplitted() 
  getBufDataSplitted() 
  getLineNoData()
  getLineEmptyLine()
  getLineOneLine()
  getLineMultiLineSplitted()
  getLineHttpRequest()
  return run, assertions
end

