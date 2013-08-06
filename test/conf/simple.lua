-- Frist simple proxy configuration 
listen("http://localhost:8080", function(Connection connection)
  connection.dispatcher("path=/foo",
  function(Request request)
    request.connect("http://localhost:9080")
  end)
end)

