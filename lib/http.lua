-- module http
request = require("request")
queue = require("queue")
local http = {}

queues = {}

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

function http.stream(connection, data, nextPlugin)
  if data ~= nil then
    local r
    local q = queues[connection]
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
      queues[connection] = q 
    end
    r = q.request
    q:pushData(data)
    if r.http == nil then
      r.http = {}
      r.http.state = "headers"
    end
    if r.http.state == "headers" then
      done = r:readHeader(nextPlugin)
      if done then
        r.http.state = "body"
        done = _readBody(r, nextPlugin)
      end
      return done
    elseif r.http.state == "body" then
      done = _readBody(r, nextPlugin)
      return done
    end
  else
    queues[connection] = nil
  end
end

return http

