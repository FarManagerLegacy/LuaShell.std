local function mapargs (...)
  local first, fn = 2, ...
  if type(fn)~="function" then
    fn = tonumber
    first = 1
  end
  return unpack(sh.map({ select(first, ...) }, function (str)
    return fn(str)
  end))
end

if _cmdline=="" then
  print "Maps passed values with specified function (or `tonumber` by default)"
  print "Example:"
  print('  mapargs(sh.eval, "{a=1}", "2", "error")',"=>")
  sh.printd(mapargs(sh.eval, "{a=1}", "2", "error"))
elseif _cmdline then
  sh.printd(mapargs(sh.eval, ...))
  --print(sh.dump{mapargs(sh.eval, ...)})
else
  return mapargs
end
