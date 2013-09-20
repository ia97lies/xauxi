function try(f, catch_f)
  local status, exception = pcall(f)
  if not status then
    catch_f(exception)
  end
end

try(function()
  -- Try block
  -- --
end, function(e)
  -- -- Except block. E.g.:
  -- --
  -- Use e for conditional catch
  -- --
  -- Re-raise with error(e)
end)
