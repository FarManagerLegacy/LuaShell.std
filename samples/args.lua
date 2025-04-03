local arg = {n=select("#", ...), ...}
print(arg.n.." arguments specified:")
for i=1,arg.n do
  print(i, ("'%s'"):format(arg[i]))
end
