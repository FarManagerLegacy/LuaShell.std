local function proxy (fn, var, ...)
  if var~=nil then
    fn(var, ...)
  end
  return var
end

local function each (...) --iterate
  local fn,iter,state,var = ...
  if select('#', ...)<3 then
    iter,fn = ...
    if type(iter)=="table" then
      iter = sh.iter_it(iter)
    end
  end
  --assert(type(fn)=="function", type(fn))
  assert(type(iter)=="function")
  assert(type(state)~="function") --most probably wrong arguments order
  repeat
    var = proxy(fn, iter(state, var))
    --assert(type(var)~="function") --most probably factory was passed instead of iterator
    if mf.waitkey(1)~="" then break end
  until var==nil
  return ...
end

if _cmdline=="" then
  print "Process each value with a function."
  print "Syntax:"
  print "  each(iter,fn) /iter: fn or list/"
  print " or"
  print "  each(fn,iter,state,init)"
  print "Example:"
  print ("  each({a=1,b=2,c=3}, print):", "=>")
  each({a=1,b=2,c=3}, print)
elseif _cmdline then
  each(sh.eval(_cmdline))
else
  return each
end
