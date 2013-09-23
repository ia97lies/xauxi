-- Sample config for xauxi
--

-- Some handler which can be regiestered
function handle_gzip(Handle handle)
  mod_deflate.init("reponse");
end

-- Simple example, 80% of the connfig should look that way
listen("http://localhost:8080", function(Connection connection)
  connection.dispatcher("path=/foo",
  function(Connection connection, Request request)
    request.register(function()
      mod_rewrite.init("/", "/foo")
    end)
    request.register(handle_gzip)
    request.connect("http://localhost:9080")
  end)
end)

-- Namebased and a conditional handle registration
listen("http://localhost:8080", "name=www.foo.ch", function(Connection connection) 
  connection.dispatcher("path=bla",
  function(Connection connection, Request request)
    request.register(function()
      mod_rewrite.init("/", "/foo")
    end)
    if (request.header("Content-Type").regex("text/html")) then
      request.register(handle_gzip)
    end
    request.connect("http://localhost:9080")
  end)
end)

-- Dispatcher depending on path and user-agent
listen("http://localhost:8081", function(Connection connection)
  connection.dispatcher(function(Connection connection)
    request = connection.get_request()
    if (request.path().equals("/bla") and 
        request.header("user-agent").regex(".*mozilla.*")) then
      return request;
    else
      return null;
    end
  end,
  function(request)
    request.register(function()
      mod_rewrite.init("/", "/bla")
    end)
    request.register(handle_gzip)
    request.connect("http://localhost:9080")
  end)
end)
