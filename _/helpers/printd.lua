local function printd (...)
  --print(unpack(sh.map({...}, sh.dump), 1, select('#',...)))
  print(sh.mapargs(sh.dump, ...))
end

if _cmdline=="" then
  print "Prints dumps of passed arguments"
  print "Example:"
  print('  printd({a=1}, "2", error)',"=>")
  printd({a=1}, "2", error)
elseif _cmdline then
  printd(sh.eval(_cmdline))
else
  return printd
end
