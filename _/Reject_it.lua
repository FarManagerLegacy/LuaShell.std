local function non(fn)
  return function (...)
    return not fn(...)
  end
end

local function reject_it (...)
  if select('#', ...)<3 then
    local iter,fn = ...
    return sh.filter_it(iter, non(fn))
  else
    local fn,iter,state,var = ...
    return sh.filter_it(non(fn), iter, state, var)
  end
end

if _cmdline=="" then
  print "Removes items that match the provided criteria."
  print "Syntax:"
  print "  reject_it(iter, fn) /iter: fn or list/"
  print " or"
  print "  reject_it(fn,iter,state,init)"
  print "Examples:"
  print ("  reject_it({1,2,3}, function(i) return i%2 == 1 end)", "=>",
        sh.dump(sh.map(reject_it({1,2,3}, function(i) return i%2 == 1 end))))
  print ("  reject_it(function(i) return i%2 == 1 end, ipairs({1,2,3}))", "=>",
        sh.dump(sh.map(reject_it(function(i) return i%2 == 1 end, ipairs({1,2,3})))))
elseif _cmdline then
  print()
  sh.each(reject_it(sh.eval(_cmdline)), sh.printd)
else
  return reject_it
end
