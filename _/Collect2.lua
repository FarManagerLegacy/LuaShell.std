local function collect2 (...)
  local iter, state, var = ...
  local collected = {}
  local ins = function (...)
    table.insert(collected, {...})
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
  print "Each returned values set is packed into separate table."
  print "Syntax:"
  print "  collect2(iter) /iter: fn or list/"
  print "Examples:"
  print ("collect2(pairs({a=1,b=2,c=3}))", "=>",
        sh.dump(collect2(pairs({a=1,b=2,c=3}))))
  print ("collect2(ipairs({3,2,1}))", "=>",
        sh.dump(collect2(ipairs({3,2,1}))))
  print ("collect2({3,2,1})", "=>",
        sh.dump(collect2({3,2,1})))

elseif _cmdline then
  print()
  sh.printd(collect2(sh.eval(_cmdline)))
else
  return collect2
end
