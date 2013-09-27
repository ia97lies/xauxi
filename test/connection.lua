#!./lua_unit

connection = require("connection")
assertions = 0
run = 0

function getBufNoData()
  io.write(string.format("getBuf"))
  run = run + 1
  local c = connection.new()
  nextChunk = c:getData(1)
  buf, done = nextChunk()
  if buf ~= nil or done ~= false then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
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
  nextChunk = c:getData(1)
  buf, done = nextChunk()
  if buf ~= "1" or done ~= true then
    io.write(string.format(" buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- second run, there must be nil 
  buf, done = nextChunk()
  if buf ~= nil or done ~= true then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
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
  nextChunk = c:getData(1)
  local buf, done = nextChunk()
  if buf ~= "1" or done ~= true then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- job finish mark nil, true as there are still data
  local buf, done = nextChunk()
  if buf ~= nil or done ~= true then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- next job to get one byte
  nextChunk = c:getData(1)
  local buf, done = nextChunk()
  if buf ~= "2" or done ~= true then
    io.write(string.format(" 3. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- job finish mark nil, true as there are still data
  local buf, done = nextChunk()
  if buf ~= nil or done ~= true then
    io.write(string.format(" 4 buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getBufByteFromTwoByte()
  io.write(string.format("getBufByteFromTwoByte"))
  run = run + 1
  local c = connection.new()
  c:pushData("12")
  -- job to get one byte
  nextChunk = c:getData(1)
  local buf, done = nextChunk()
  if buf ~= "1" or done ~= true then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- job finish mark nil, true as there are still data
  local buf, done = nextChunk()
  if buf ~= nil or done ~= true then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- next job to get one byte
  nextChunk = c:getData(1)
  local buf, done = nextChunk()
  if buf ~= "2" or done ~= true then
    io.write(string.format(" 3. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  -- job finish mark nil, true as there are still data
  local buf, done = nextChunk()
  if buf ~= nil or done ~= true then
    io.write(string.format(" 4 buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(more)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getBufWordFromTooLessData()
  io.write(string.format("getBufWordFromTooLessData"))
  run = run + 1
  local c = connection.new()
  c:pushData("12")
  -- job to get a word of 3 bytes
  nextChunk = c:getData(3)
  local buf, done = nextChunk()
  if buf ~= "12" or done ~= false then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  local buf, done = nextChunk()
  if buf ~= nil or done ~= false then
    io.write(string.format(" 2 buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- push additional data
  c:pushData("34")
  local buf, done = nextChunk()
  if buf ~= "3" or done ~= true then
    io.write(string.format(" 3. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  -- job finish mark nil, true as there are still data
  local buf, done = nextChunk()
  if buf ~= nil or done ~= true then
    io.write(string.format(" 4 buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getBufWordFromTooManyData()
  io.write(string.format("getBufWordFromTooManyData"))
  run = run + 1
  local c = connection.new()
  c:pushData("123456789")
  -- job to get a word of 3 bytes
  nextChunk = c:getData(3)
  local buf, done = nextChunk()
  if buf ~= "123" or done ~= true then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end
  nextChunk = c:getData(3)
  local buf, done = nextChunk()
  if buf ~= "456" or done ~= true then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    io.write(string.format(" done is "..tostring(done)))
    io.write(string.format(" failed\n"))
    assertions = assertions + 1
    return
  end

end

function connectionEmpty()
  io.write(string.format("connectionEmpty"))
  run = run + 1
  local c = connection.new()
  if c:isEmpty() ~= true then
    io.write(string.format(" Connection is not empty?"))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function connectionNotEmpty()
  io.write(string.format("connectionNotEmpty"))
  run = run + 1
  local c = connection.new()
  c:pushData("1")
  if c:isEmpty() ~= false then
    io.write(string.format(" Connection is empty?"))
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
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getLineEmptyLine()
  io.write(string.format("getLineEmptyLine"))
  run = run + 1
  local c = connection.new()
  c:pushData("\r\n")
  local buf = c:getLine()
  if buf ~= "" then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    assertions = assertions + 1
    return
  end
  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getLineOneByte()
  io.write(string.format("getLineOneByte"))
  run = run + 1
  local c = connection.new()
  c:pushData("1\r\n")
  local buf = c:getLine()
  if buf ~= "1" then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    assertions = assertions + 1
    return
  end
  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getLineOneByteScatterdData()
  io.write(string.format("getLineOneByteScatterdData"))
  run = run + 1
  local c = connection.new()
  c:pushData("1\r")
  c:pushData("\n")
  local buf = c:getLine()
  if buf ~= "1" then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    assertions = assertions + 1
    return
  end
  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function getLineWordScatterdData()
  io.write(string.format("getLineWordScatterdData"))
  run = run + 1
  local c = connection.new()
  c:pushData("Hal")
  c:pushData("lo W")
  c:pushData("elt")
  c:pushData("\r")
  c:pushData("\n")
  local buf = c:getLine()
  if buf ~= "Hallo Welt" then
    io.write(string.format(" 1. buf is "..tostring(buf)))
    assertions = assertions + 1
    return
  end
  local buf = c:getLine()
  if buf ~= nil then
    io.write(string.format(" 2. buf is "..tostring(buf)))
    assertions = assertions + 1
    return
  end

  io.write(string.format(" ok\n"))
end

function test()
  getBufNoData() 
  getBufOneByte() 
  getBufByteByByte() 
  getBufByteFromTwoByte()
  getBufWordFromTooLessData()
  getBufWordFromTooManyData()
  connectionEmpty()
  connectionNotEmpty()
  getLineNoData()
  getLineEmptyLine()
  getLineOneByte()
  getLineOneByteScatterdData()
  getLineWordScatterdData()
  return run, assertions
end

