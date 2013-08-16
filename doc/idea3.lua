global = 
{
  { 
    listen = "localhost:8080", 
    filter = function(Connection conn)
               if conn.remote_ip == "192.168.1.13" then
                 return 0
               else
                 return 1
               end
             end
    { 
      dispatcher = function(Request req) 
                     if req.uri() == "/foo" then 
                       return true 
                     else 
                       return false 
                     end 
                   end, 
      filter = function(Request req) 
                 rewrite(req, "/foo", "/foo/bar");
               end 
      connect = function(Request req)
                 backend = connect(req, "192.168.1.55:80");
                 backend.pass(req);
                end
    }
    {
      dispatcher = function(Request req) return location(req, "/foo") end 
      connect = function(Request req)
                 backend = connect(req, "192.168.1.55:80");
                 backend.pass(req);
                end
    }
  }
}

