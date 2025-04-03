local function isArray (value)
  return type(value) == "table" and (value[1] or next(value) == nil)
end

local function iter_it (list)
  local pairing = isArray(list) and ipairs or pairs
  local iter,state,var = pairing(list)
  return function ()
    local k,v = iter(state, var)
    var = k
    return v, k
  end
end

if _cmdline=="" then
  print "Creates an iterator function over a list (array/table)."
  print "Each fn call will return `value,key` pair."
  print "Syntax: iter_it(list)"
  print "Example:"
  print("  each(iter_it({3,2,1}))", "=>")
  sh.each(iter_it({3,2,1}), print)
  print("  each(iter_it({a=1,b=2,c=3}))", "=>")
  sh.each(iter_it({a=1,b=2,c=3}), print)
elseif _cmdline then
  print()
  sh.each(iter_it(sh.eval(_cmdline)), sh.printd)
else
  return iter_it
end
