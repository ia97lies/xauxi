#!./lua_unit

connection = require("connection")
assertions = 0
run = 0

function getBufNoData()
  io.write(string.format("getBuf"))
  run = run + 1
  local c = connection.new()
  local buf = c:getData(1)
  if buf ~= nil then
    io.write(string.format(" buf is "..buf))
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
  local buf = c:getData(1)
  if buf ~= "1" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- second run, there must be nil 
  buf = c:getData(1)
  if buf ~= nil then
    io.write(string.format(" second run buf is "..buf))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  io.write(string.format(" ok\n"))
end

function getBufTwoBytes()
  io.write(string.format("getBufTwoBytes"))
  run = run + 1
  local c = connection.new()
  c:pushData("12")
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
    io.write(string.format(" second run buf is "..buf))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getBufTwoBytesSplitted()
  io.write(string.format("getBufTwoBytes"))
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
    io.write(string.format(" second run buf is "..buf))
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
  -- first run, there must be "1" 
  local buf = c:getData(10)
  if buf ~= "1234567890" then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function test()
  getBufNoData() 
  getBufOneByte() 
  getBufTwoBytes() 
  getBufTwoBytesSplitted() 
  getBufDataSplitted() 
  return run, assertions
end

