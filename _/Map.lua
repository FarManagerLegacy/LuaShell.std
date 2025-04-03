local function map (list,fn)
  local mapped = {}
  sh.each(list, function (v,k)
    table.insert(mapped, fn and fn(v,k,list) or v)
  end)
  return mapped
end

if _cmdline=="" then
  print "Produces a new array by mapping each value in list through a transformation function."
  print "Syntax: map(list,fn)"
  print "Notes:"
  print "  Iterator can be passed as list arg."
  print "  Transformation function is optional, so `map` can be used to just collect values from iterator."
  print "Examples:"
  print ("map({a=1,b=2,c=3}, function(x) return x*2 end)", "=>",
        sh.dump(map({a=1,b=2,c=3}, function(x) return x*2 end)))
  print ("map(sh.range_it(1,5,2))", "=>",
        sh.dump(map(sh.range_it(1,5,2))))
elseif _cmdline then
  print()
  sh.printd(map(sh.eval(_cmdline)))
else
  return map
end
