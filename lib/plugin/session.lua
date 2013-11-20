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

local plugin = {}
local id = 0
local _sessionStore

local serializer = require "xauxi.serialize"

function _generateSessionId()
  id = id + 1
  return id
end

-- TODO: with lua enviroment _G, but seems not working, no clue why


------------------------------------------------------------------------------
-- Init function for this plugin
-- @param sessionStore IN session store handle
------------------------------------------------------------------------------
function plugin.init(sessionStore)
  _sessionStore = sessionStore
end

------------------------------------------------------------------------------
-- Data input
-- @param event IN 'begin', 'data', 'end'
-- @param req IN request
-- @param res IN response
-- @param chunk IN data chunk
------------------------------------------------------------------------------
function plugin.input(event, req, res, chunk)
  req.session = {}
end

------------------------------------------------------------------------------
-- Data output
-- @param event IN 'begin', 'data', 'end'
-- @param req IN request
-- @param res IN response
-- @param chunk IN data chunk
------------------------------------------------------------------------------
function plugin.output(event, req, res, chunk)
  if req.session ~= nil then
    req.sessionId = _generateSessionId()
    _sessionStore.set(req.sessionId, req.session)
  end
end

return plugin
