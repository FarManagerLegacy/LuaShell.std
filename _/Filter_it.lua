local function filter_it (...)
  local fn,iter,state,var = ...
  if select('#', ...)<3 then
    iter,fn = ...
    if type(iter)=="table" then
      iter = sh.iter_it(iter)
    end
  end
  local function process (...)
    if ...==nil then return nil end
    var = ...
    if fn(...) then
      return ...
    end
    return process(iter(state,var))
  end
  return function()
    return process(iter(state,var))
  end
end

if _cmdline=="" then
  print "Removes items that do not match the provided criteria."
  print "Syntax:"
  print "  filter_it(iter, fn) /iter: fn or list/"
  print " or"
  print "  filter_it(fn,iter,state,init)"
  print "Examples:"
  print ("  filter_it({1,2,3}, function(i) return i%2 == 1 end)", "=>",
        sh.dump(sh.map(filter_it({1,2,3}, function(i) return i%2 == 1 end))))
  print ("  filter_it(function(i) return i%2 == 1 end, ipairs({1,2,3}))", "=>",
        sh.dump(sh.map(filter_it(function(i) return i%2 == 1 end, ipairs({1,2,3})))))
elseif _cmdline then
  print()
  print(sh.dump(sh.collect(filter_it(sh.eval(_cmdline)))))
else
  return filter_it
end

