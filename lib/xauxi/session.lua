------------------------------------------------------------------------------
-- Copyright 2013 Christian Liesch
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
------------------------------------------------------------------------------

local sessionStore = {}
local inmemoryDriver = { db = {} }
local _driver
local _timeout
local _tinaltimeout

------------------------------------------------------------------------------
-- Connect to a DB
-- @param driver IN DB driver
------------------------------------------------------------------------------
function sessionStore.connect(driver, timout, finalTimeout)
  if driver == nil then
    _driver = inmemoryDriver
  else
    _driver = driver
  end
  _timeout = timout
  _finalTimeout = finalTimeout
end


------------------------------------------------------------------------------
-- Set entry
------------------------------------------------------------------------------
function sessionStore.set(id, session)
  _driver.set(id, session)
end

------------------------------------------------------------------------------
-- Get entry
------------------------------------------------------------------------------
function sessionStore.get(id)
  return _driver.get(id)
end

------------------------------------------------------------------------------
-- Delete entry
------------------------------------------------------------------------------
function sessionStore.del(id)
  return _driver.del(id)
end

------------------------------------------------------------------------------
-- Delete entry
------------------------------------------------------------------------------
function sessionStore.noOfEntries()
  return _driver.noOfEntries()
end

------------------------------------------------------------------------------
-- Do delete all out dated entries
------------------------------------------------------------------------------
function sessionStore.maintenance()
  return _driver.maintenance()
end

------------------------------------------------------------------------------
-- Get builtin inmemory driver 
------------------------------------------------------------------------------
function sessionStore.getInmemoryDriver()
  return inmemoryDriver
end

------------------------------------------------------------------------------
-- Builtin inmemory driver
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Set entry
------------------------------------------------------------------------------
function inmemoryDriver.set(key, value)
  entry = { value, os.time(), os.time() }
  inmemoryDriver.db[key] = entry
end

------------------------------------------------------------------------------
-- Check if entry is valid
------------------------------------------------------------------------------
function inmemoryDriver.isValid(entry) 
   if _timeout == 0 or os.time() - entry[2] < _timeout then
    if _finalTimeout == 0 or os.time() - entry[3] < _finalTimeout then
      return true
    else
      return false 
    end
  else
    return false
  end
end

------------------------------------------------------------------------------
-- Get entry
------------------------------------------------------------------------------
function inmemoryDriver.get(key, value)
  entry = inmemoryDriver.db[key]
  if entry then
    if inmemoryDriver.isValid(entry) then
      entry[2] = os.time()
      return entry[1]
    else
      inmemoryDriver.db[key] = nil
      return nil
    end
  else
    return nil
  end
end
  
------------------------------------------------------------------------------
-- Delete entry
------------------------------------------------------------------------------
function inmemoryDriver.del(key)
  inmemoryDriver.db[key] = nil
end
   
------------------------------------------------------------------------------
-- No of entries
------------------------------------------------------------------------------
function inmemoryDriver.noOfEntries()
  count = 0
  for _, v in pairs(inmemoryDriver.db) do
    count = count + 1
  end
  return count
end
 
------------------------------------------------------------------------------
-- Maintenance
------------------------------------------------------------------------------
function inmemoryDriver.maintenance()
  count = 0
  for id, entry in pairs(inmemoryDriver.db) do
    if not inmemoryDriver.isValid(entry) then
      inmemoryDriver.db[id] = nil
    end
  end
end

return sessionStore

