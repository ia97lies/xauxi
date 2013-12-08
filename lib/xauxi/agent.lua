local net = require("luanode.net")
local Agent = {}
Agent.sockets = {}
Agent.maxSockets = 1
Agent.options = {}

function Agent:addRequest (req, host, port, localAddress)
  print("XXX addRequest")
  conn = net.createConnection({
    port = port,
    host = host,
    localAddress = localAddress
  })
  req:onSocket(conn)
end

function Agent:createSocket (name, host, port, localAddress, req)
  print("XXX createSocket")
end

---
--
function Agent:removeSocket (socket, name, host, port, localAddress)
  print("XXX removeSocket")
end

return Agent
