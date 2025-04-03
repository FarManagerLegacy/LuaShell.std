local function collect (...)
  local n, iter, state, var = ...
  if type(n)~="number" then
    n,iter,state,var = 1, ...
  end
  local collected = {}
  local ins = function (...)
    table.insert(collected, (select(n, ...)))
  end
  if select("#", ...)<3 then
    sh.each(iter,ins)
  else
    sh.each(ins,iter,state,var)
  end
  return collected
end

if _cmdline=="" then
  print "Produces a new array by collecting values returned by iter function."
  print "Syntax:"
  print "  collect(iter) /iter: fn or list/"
  print " or"
  print "  collect(n,iter) /collect n-th value/"
  print "Examples:"
  print ("collect(pairs({a=1,b=2,c=3}))", "=>",
        sh.dump(collect(pairs({a=1,b=2,c=3}))))
  print ("collect(2, ipairs({3,2,1}))", "=>",
        sh.dump(collect(2, ipairs({3,2,1}))))

elseif _cmdline then
  print()
  sh.printd(collect(sh.eval(_cmdline)))
else
  return collect
end
