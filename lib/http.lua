-- module http
request = require("request")
queue = require("queue")
local http = {}

frontends = {}
backends = {}

-- private
function _readBody(r, nextPlugin)
  done = r:readBody(nextPlugin)
  if done then
    r.queue.request = nil
  end
  return done
end

-- public
function http.location(uri, loc)
  return string.sub(uri, 1, string.len(loc)) == loc
end

function http.frontend(connection, data, nextPlugin)
  if data ~= nil then
    local r
    local q = frontends[connection]
    if q ~= nil then
      if q.request == nil then
        r = request.new()
        q.request = r
        r.queue = q 
        r.connection = connection
      end
    else
      q = queue.new()
      r = request.new()
      q.request = r
      r.queue = q 
      r.connection = connection
      frontends[connection] = q 
    end
    r = q.request
    q:pushData(data)
    if r.state == nil then
      r.state = "headers"
    end
    if r.state == "headers" then
      done = r:readHeader(nextPlugin)
      if done then
        r.state = "body"
        done = _readBody(r, nextPlugin)
      end
      return done
    elseif r.state == "body" then
      done = _readBody(r, nextPlugin)
      return done
    end
  else
    frontends[connection] = nil
  end
end

function passBody(res, data)
  -- TODO if transfer-encoding: chunked send the chunk infos beside the data
  if data == nil then
    res.state = "recv.headers"
  else
    res.connection:write(data)
  end
end

function pass(req, res, data, nextPlugin)
  if res.state == nil then
    res.state = "send.headers"
  end
  if res.state == "send.headers" then
    res.connection:write(req.method.." "..req.uri.." HTTP/"..req.version.."\r\n");
    for _, header in pairs(req.headers) do
      res.connection:write(header.name..": "..header.value.."\r\n")
    end
    -- TODO if data ~= nil and content-length header missing set 
    --      transfer-encoding: chunked
    res.connection:write("\r\n")
    passBody(res, data)
    res.state = "send.body"
  elseif res.state == "recv.headers" then
  elseif res.state == "recv.body" then
  else
    passBody(res, data)
  end
  nextPlugin(res.connection)
end

function http.backend(req, host, data, nextPlugin)
 local backend = backends[req.connection]
  if backend ~= nil then
    pass(req, req.response, data, nextPlugin);
  else
    connect(host, req.connection, function(backend)
      local res = request.new()
      local q = queue.new()
      q.request = res
      res.queue = q 
      res.connection = backend 
      req.response = res
      backends[res.connection] = backend;
      pass(req, req.response, data, nextPlugin);
    end)
  end
end

return http

