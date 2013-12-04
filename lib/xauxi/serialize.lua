------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
-- Provide under MIT License
--
-- Serialize Table
--   Used for session table serialization to store it in a DB like 
--   redis/memcachd
------------------------------------------------------------------------------

local _serializer = {}

local function printValue(v)
  if type(v) == "number" then
    return v
  elseif type(v) == "string" then
    return "\""..v.."\""
  elseif type(v) == "table" then
    return _serializer.serialize(v)
  end
end

function _serializer.serialize(t)
  local result = {} 
  if type(t) == "table" then
    table.insert(result, "{") 
    local row = {}
    for k,v in ipairs(t) do
      if type(k) == "number" then
        table.insert(row, printValue(v))
      elseif type(k) == "string" then
        table.insert(row, k.."="..printValue(v))
      end
    end
    table.insert(result, table.concat(row, ","))
    table.insert(result, "}") 
  else
    error("not a table")
  end
  return table.concat(result);
end

return _serializer

