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

local _plugin = {}
local _id = 0
local _sessionStore
local _sessionName = "xisession"

local serializer = require "xauxi.serialize"

function _generateSessionId()
  _id = _id + 1
  return _id
end

-- TODO: with lua enviroment _G, but seems not working, no clue why


------------------------------------------------------------------------------
-- Init function for this _plugin
-- @param sessionStore IN session store handle
------------------------------------------------------------------------------
function _plugin.init(sessionStore, sessionName)
  _sessionStore = sessionStore
  _sessionName = sessionName
end

------------------------------------------------------------------------------
-- Data input
-- @param event IN 'begin', 'data', 'end'
-- @param req IN request
-- @param res IN response
-- @param chunk IN data chunk
------------------------------------------------------------------------------
function _plugin.input(event, req, res, chunk)
  req.session = {}
end

------------------------------------------------------------------------------
-- Data output
-- @param event IN 'begin', 'data', 'end'
-- @param req IN request
-- @param res IN response
-- @param chunk IN data chunk
------------------------------------------------------------------------------
function _plugin.output(event, req, res, chunk)
  if req.session ~= nil then
    req.sessionId = _generateSessionId()
    _sessionStore.set(req.sessionId, req.session)
    if res.headers["set-cookie"] == nil then
      res.headers["set-cookie"] = {}
    end
    table.insert(res.headers["set-cookie"], _sessionName.."="..req.sessionId)
  end
end

return _plugin
