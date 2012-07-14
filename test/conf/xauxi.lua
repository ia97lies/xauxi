
function global(g)
  print("hello world")
  --server(function(g, s) 
  --  s:listen("http://localhost:8080");
  --  s:location("/foo", function(g,s,l) 
  --    pass("http://localhost:8090")
  --end)
end

