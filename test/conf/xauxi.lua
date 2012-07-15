
function global()
  print("hello world")

  server("http://localhost:8080", function()
    location("/foo", function()
      return"content foo";
    end);

    location("/bar", function()
      return "content bar";
    end);
  end);

  server("http://localhost:8081", function()
    location("/foo", function()
      return "content foo";
    end);
  end);

end

