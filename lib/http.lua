-- module http
request = require("request")
queue = require("queue")
local http = {}

input = {}
output = {}

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
    local q = input[connection]
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
      input[connection] = q 
    end
    r = q.request
    q:pushData(data)
    if r.frontend == nil then
      r.frontend = {}
      r.frontend.state = "headers"
    end
    if r.frontend.state == "headers" then
      done = r:readHeader(nextPlugin)
      if done then
        r.frontend.state = "body"
        done = _readBody(r, nextPlugin)
      end
      return done
    elseif r.frontend.state == "body" then
      done = _readBody(r, nextPlugin)
      return done
    end
  else
    input[connection] = nil
  end
end

function passBody(r, backend, data)
  -- TODO if transfer-encoding: chunked send the chunk infos beside the data
  if data == nil then
    r.backend.state = "recv.headers"
  else
    backend:write(data)
  end
end

function pass(r, backend, data, nextPlugin)
  if r.backend == nil then
    r.backend = {}
    r.backend.state = "send.headers"
  end
  if r.backend.state == "send.headers" then
    backend:write(r.method.." "..r.uri.." HTTP/"..r.version.."\r\n");
    for _, header in pairs(r.headers) do
      backend:write(header.name..": "..header.value.."\r\n")
    end
    -- TODO if data ~= nil and content-length header missing set 
    --      transfer-encoding: chunked
    backend:write("\r\n")
    passBody(r, backend, data)
    r.backend.state = "send.body"
  elseif r.backend.state == "recv.headers" then
  elseif r.backend.state == "recv.body" then
  else
    passBody(r, backend, data)
  end
  nextPlugin(backend)
end

function http.backend(r, host, data, nextPlugin)
 local backend = output[r.connection]
  if backend ~= nil then
    pass(r, backend, nextPlugin);
  else
    connect(host, r.connection, function(backend)
      input[r.connection] = backend;
      pass(r, backend, data, nextPlugin);
    end)
  end
end

return http

