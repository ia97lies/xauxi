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
    io.write(string.format(" buf is "..tostring(buf)))
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
    io.write(string.format(" second run buf is "..tostring(buf)))
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
    io.write(string.format(" second run buf is "..tostring(buf)))
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

function getLineOneLineSplitted()
  io.write(string.format("getLineOneLineSplitted"))
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

function test()
  getBufNoData() 
  getBufOneByte() 
  getBufTwoBytes() 
  getBufTwoBytesSplitted() 
  getBufDataSplitted() 
  getLineNoData()
  getLineEmptyLine()
  getLineOneLine()
  getLineOneLineSplitted()
  return run, assertions
end

