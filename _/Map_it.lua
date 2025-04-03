local function map_it (...)
  local fn,iter,state,var = ...
  if select('#', ...) <3 then
    iter,fn = ...
    if type(iter)=="table" then
      iter = sh.iter_it(iter)
    end
  end
  return function ()
    return (function (...)
      if ...==nil then return nil end
      var = ...
      return fn(...)
    end)(iter(state, var))
  end
end

if _cmdline=="" then
  print "Map each item with a transformation function."
  print "Syntax:"
  print "  map_it(iter, fn) /iter: fn or list/"
  print " or"
  print "  map_it(fn,iter,state,init)"
  print "Examples:"
  print ("map_it({a=1,b=2,c=3}, function(x) return x*2 end)", "=>",
        sh.dump(sh.collect(map_it({a=1,b=2,c=3}, function(x) return x*2 end))))
  print ("map_it(sh.range_it(1,5,2), function(x) return x+1 end)", "=>",
        sh.dump(sh.collect(map_it(sh.range_it(1,5,2), function(x) return x+1 end))))
  print ("map_it(function(x) return x-1 end, ipairs{3,2,1}", "=>",
        sh.dump(sh.collect(map_it(function(x) return x-1 end, ipairs{3,2,1}))))
elseif _cmdline then
  print()
  sh.printd(map_it(sh.eval(_cmdline)))
else
  return map_it
end
